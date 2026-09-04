pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The display and aggregation engine for agent usage.
// All extraction lives behind scripts/agent-usage-update, which writes one JSON record
// per agent into ~/.local/state/quickshell/agents/usage/; this singleton discovers those records,
// watches them for live changes, aggregates synced multi-device metrics, and provides
// display-ready data to both the bar widget and popup panel.
Item {
    id: root
    visible: false

    readonly property string home: Quickshell.env("HOME") || ""
    readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || (home + "/.config")) + "/quickshell"
    readonly property string usageDir: (Quickshell.env("XDG_STATE_HOME") || home + "/.local/state") + "/quickshell/agents/usage"
    readonly property string updateScriptPath: configDir + "/scripts/agent-usage-update"

    // ------------------------------------------------------------- discovery

    property var agentIds: []
    property var agents: []
    property int dataRevision: 0
    property string selectedProviderId: ""

    Process {
        id: listProcess
        running: false
        command: ["find", root.usageDir, "-maxdepth", "1", "-name", "*.json", "-printf", "%f\n"]

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.applyAgentListing(text)
        }
    }

    function rescanAgents() {
        if (!listProcess.running) listProcess.running = true
    }

    function applyAgentListing(output) {
        var ids = []
        var lines = String(output || "").split("\n")
        for (var i = 0; i < lines.length; i++) {
            var name = lines[i].trim()
            if (name.slice(-5) === ".json" && !name.startsWith(".")) {
                ids.push(name.slice(0, -5))
            }
        }
        ids.sort()
        if (JSON.stringify(ids) !== JSON.stringify(agentIds)) {
            agentIds = ids
        }
    }

    Instantiator {
        id: agentInstantiator
        model: root.agentIds

        delegate: Item {
            id: agentItem
            visible: false
            required property var modelData
            property string agentId: modelData
            property string path: root.usageDir + "/" + modelData + ".json"
            property var record: null

            FileView {
                path: agentItem.path
                watchChanges: true
                printErrors: false
                onFileChanged: reload()
                onLoaded: agentItem.parse(text())
                onLoadFailed: agentItem.record = null
            }

            function parse(content) {
                try {
                    var parsed = JSON.parse(String(content || ""))
                    agentItem.record = parsed && typeof parsed === "object" ? parsed : null
                } catch (e) {
                    console.warn("agents", "Ignoring bad usage record", agentItem.path, e)
                    agentItem.record = null
                }
            }

            onRecordChanged: root.recordsChanged()
        }

        onObjectAdded: (index, object) => root.rebuildAgents()
        onObjectRemoved: (index, object) => root.rebuildAgents()
    }

    function rebuildAgents() {
        var result = []
        for (var i = 0; i < agentInstantiator.count; i++) {
            var agent = agentInstantiator.objectAt(i)
            if (agent) result.push(agent)
        }
        agents = result
        recordsChanged()
    }

    function recordsChanged() {
        dataRevision++
        scheduleLimitsRetry()
        scheduleSync()
    }

    // -------------------------------------------------------- limits retry

    property var retryAgentIds: []

    Timer {
        id: limitsRetry
        interval: 30000
        repeat: false
        onTriggered: root.runUpdate("limits", root.retryAgentIds)
    }

    function scheduleLimitsRetry() {
        var advising = []
        for (var i = 0; i < agents.length; i++) {
            var record = agents[i] ? agents[i].record : null
            if (record && record.retryAdvised === true && providerEnabled(String(record.id || "")))
                advising.push(String(record.id))
        }
        retryAgentIds = advising
        if (advising.length > 0) limitsRetry.restart()
        else limitsRetry.stop()
    }

    Component.onCompleted: {
        rescanAgents()
        if (syncConfigured()) scheduleSync()
    }

    // -------------------------------------------------------------- refresh

    property int refreshIntervalSec: Math.max(30, Settings.aiUsageRefreshMinutes * 60)
    property string pendingUpdateKind: ""
    property double lastUpdatedMs: Date.now()
    readonly property bool updating: updateProcess.running

    Timer {
        interval: Math.max(30000, root.refreshIntervalSec * 1000)
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.runUpdate("normal")
    }

    Process {
        id: updateProcess
        running: false
        onExited: {
            root.lastUpdatedMs = Date.now()
            root.rescanAgents()
            if (root.pendingUpdateKind !== "") {
                var kind = root.pendingUpdateKind
                root.pendingUpdateKind = ""
                root.runUpdate(kind)
            }
        }

        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: if (text.trim() !== "") console.warn("agents", text.trim())
        }
    }

    function updateCommand(kind, agentIds) {
        var command = [root.updateScriptPath]
        if (kind === "force") command.push("--force")
        if (kind === "limits") command.push("--limits-only")

        var enabledStr = Settings.aiUsageProviders || ""
        var enabledList = enabledStr.split(",").map(s => s.trim()).filter(s => s.length > 0)

        // For each known agent that is not enabled in settings, pass --except
        for (var i = 0; i < root.agentIds.length; i++) {
            var id = root.agentIds[i]
            if (enabledList.length > 0 && !enabledList.includes(id)) {
                command.push("--except", id)
            }
        }

        if (agentIds && agentIds.length > 0) {
            for (var j = 0; j < agentIds.length; j++) command.push(agentIds[j])
        }
        return command
    }

    function runUpdate(kind, agentIds) {
        if (updateProcess.running) {
            if (kind === "force" || root.pendingUpdateKind === "") root.pendingUpdateKind = kind
            return
        }
        updateProcess.command = updateCommand(kind, agentIds)
        updateProcess.running = true
    }

    function refresh() { refreshAll(true) }
    function refreshAll(force) { runUpdate(force === true ? "force" : "normal") }
    function refreshLimits() { runUpdate("limits") }

    // ------------------------------------------------------------- providers

    property var enabledProviders: {
        var rev = dataRevision
        var syncRev = syncRevision
        var result = []
        var localIds = {}

        for (var i = 0; i < agents.length; i++) {
            var record = agents[i] ? agents[i].record : null
            if (!record || !record.id) continue
            var id = String(record.id)
            localIds[id] = true
            if (!providerEnabled(id)) continue
            var display = displayProvider(record)
            if (providerHasData(display)) result.push(display)
        }

        var syncedProviders = syncConfigured() && aggregateData && aggregateData.providers ? aggregateData.providers : {}
        for (var syncedId in syncedProviders) {
            if (localIds[syncedId] || !providerEnabled(syncedId)) continue
            var stats = syncedProviders[syncedId] || {}
            var syncedDisplay = displayProvider({ id: syncedId, name: stats.providerName || syncedId })
            if (providerHasData(syncedDisplay)) result.push(syncedDisplay)
        }
        return result
    }

    readonly property int selectedProviderIndex: {
        if (enabledProviders.length === 0) return 0
        for (var i = 0; i < enabledProviders.length; i++) {
            if (enabledProviders[i].providerId === selectedProviderId) return i
        }
        return 0
    }

    readonly property var selectedProvider: enabledProviders.length > 0 ? enabledProviders[selectedProviderIndex] : null

    function selectProvider(index) {
        if (enabledProviders.length === 0) return
        var wrapped = ((index % enabledProviders.length) + enabledProviders.length) % enabledProviders.length
        selectedProviderId = enabledProviders[wrapped].providerId
    }

    function providerEnabled(id) {
        if (!Settings.showAiUsage) return false
        var allowed = Settings.aiUsageProviders || ""
        if (allowed === "") return true
        var list = allowed.split(",").map(s => s.trim())
        return list.includes(id)
    }

    function providerHasData(p) {
        return numberValue(p.totalPrompts) > 0 || numberValue(p.totalSessions) > 0
            || numberValue(p.activeDays) > 0 || numberValue(p.todayPrompts) > 0
            || numberValue(p.todaySessions) > 0 || (p.limits && p.limits.length > 0)
            || !!p.balance
    }

    function balanceValue(raw) {
        if (!raw || typeof raw !== "object") return null
        var remaining = Number(raw.remaining)
        var funded = Number(raw.funded)
        if (!isFinite(remaining) || remaining < 0) return null
        return {
            remaining: remaining,
            funded: isFinite(funded) && funded > 0 ? funded : 0,
            spent: Math.max(0, Number(raw.spent) || 0),
            currency: String(raw.currency || "USD"),
            estimated: raw.estimated === true
        }
    }

    function displayProvider(record) {
        var stats = syncedStatsFor(String(record.id))
        var synced = !!stats
        var deviceCount = synced ? Number(stats.deviceCount || aggregateData.deviceCount || 0) : 0

        return {
            providerId: String(record.id),
            providerName: String(record.name || record.id),
            shortName: shortName(record.id),
            ready: record.ready === true || synced,
            usageStatusText: String(record.usageStatusText || ""),
            authHelpText: String(record.authHelpText || ""),
            limits: Array.isArray(record.limits) ? record.limits : [],
            tierLabel: String(record.tierLabel || ""),
            balance: balanceValue(record.balance),

            todayPrompts: synced ? numberValue(stats.todayPrompts) : numberValue(record.todayPrompts),
            todaySessions: synced ? numberValue(stats.todaySessions) : numberValue(record.todaySessions),
            todayTotalTokens: synced ? numberValue(stats.todayTotalTokens) : numberValue(record.todayTotalTokens),
            todayTokensByModel: synced ? (stats.todayTokensByModel || ({})) : (record.todayTokensByModel || ({})),
            recentDays: synced ? (stats.recentDays || []) : (record.recentDays || []),
            totalPrompts: synced ? numberValue(stats.totalPrompts) : numberValue(record.totalPrompts),
            totalSessions: synced ? numberValue(stats.totalSessions) : numberValue(record.totalSessions),
            activeDays: synced ? numberValue(stats.activeDays) : numberValue(record.activeDays),
            modelUsage: synced ? (stats.modelUsage || ({})) : (record.modelUsage || ({})),
            hasLocalStats: synced ? (stats.hasLocalStats !== false) : (record.hasLocalStats !== false),
            hasPromptStats: synced ? (stats.hasPromptStats !== false) : (record.hasPromptStats !== false),

            syncEnabled: synced,
            syncDeviceCount: deviceCount,
            syncUpdatedAt: aggregateData && aggregateData.updatedAt ? aggregateData.updatedAt : ""
        }
    }

    // ------------------------------------------------------------------ sync

    property bool syncEnabled: Settings.aiUsageSyncMode === "On"
    property string syncDir: Settings.aiUsageSyncDir || ""
    property string syncFileName: Settings.aiUsageSyncFileName || ""
    property string syncDeviceId: Settings.aiUsageSyncDeviceId || ""
    property string detectedHostname: ""
    readonly property string syncEffectiveDir: expandPath(syncDir)
    readonly property string syncEffectiveFileName: safeSnapshotFileName(syncFileName, syncDeviceId)
    readonly property string syncEffectiveDeviceId: safeDeviceId(syncDeviceId || syncEffectiveFileName.replace(/\.json$/i, ""))
    readonly property string syncSnapshotPath: syncConfigured() ? syncEffectiveDir + "/" + syncEffectiveFileName : home + "/.cache/quickshell/agents-disabled.json"
    property var aggregateData: ({})
    property int syncRevision: 0
    property bool syncRunning: false
    property bool syncRequestedWhileRunning: false
    property string syncStatusText: ""
    property double aggregateUpdatedAtMs: aggregateData && aggregateData.updatedAtMs ? Number(aggregateData.updatedAtMs) : 0

    onSyncEnabledChanged: syncSettingsChanged()
    onSyncDirChanged: syncSettingsChanged()
    onSyncFileNameChanged: if (syncConfigured()) scheduleSync()
    onSyncDeviceIdChanged: if (syncConfigured()) scheduleSync()

    Timer {
        id: syncDebounce
        interval: 1000
        repeat: false
        onTriggered: root.runSync()
    }

    Process {
        id: syncMkdirProcess
        running: false
        onRunningChanged: root.updateSyncRunning()
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                if (root.syncConfigured()) root.syncStatusText = "Usage sync mkdir failed"
                root.finishSyncRun()
                return
            }
            root.writeSyncSnapshot()
        }
    }

    Process {
        id: syncScanProcess
        running: false
        onRunningChanged: root.updateSyncRunning()
        onExited: function(exitCode) {
            if (exitCode !== 0 && root.syncConfigured()) root.syncStatusText = "Usage sync scan failed"
            root.finishSyncRun()
        }

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.parseSyncScanOutput(text)
        }

        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: if (text.trim() !== "") console.warn("agents/sync", text.trim())
        }
    }

    FileView {
        id: syncSnapshotFile
        path: root.syncSnapshotPath
        watchChanges: false
        atomicWrites: true
        printErrors: false
    }

    FileView {
        id: hostnameFile
        path: "/etc/hostname"
        watchChanges: false
        printErrors: false
        onLoaded: root.detectedHostname = String(text() || "").trim()
    }

    function syncConfigured() {
        return root.syncEnabled === true && String(root.syncDir || "").trim() !== ""
    }

    function syncSettingsChanged() {
        if (syncConfigured()) {
            scheduleSync()
        } else {
            syncDebounce.stop()
            syncRequestedWhileRunning = false
            aggregateData = ({})
            syncStatusText = ""
            syncRevision++
        }
    }

    function updateSyncRunning() {
        root.syncRunning = syncMkdirProcess.running || syncScanProcess.running
    }

    function scheduleSync() {
        if (!syncConfigured()) return
        syncDebounce.restart()
    }

    function runSync() {
        if (!syncConfigured()) return
        if (root.syncRunning) {
            syncRequestedWhileRunning = true
            return
        }

        syncRequestedWhileRunning = false
        syncStatusText = ""
        syncMkdirProcess.command = ["mkdir", "-p", root.syncEffectiveDir]
        syncMkdirProcess.running = true
    }

    function writeSyncSnapshot() {
        if (!syncConfigured()) {
            finishSyncRun()
            return
        }
        syncSnapshotFile.setText(JSON.stringify(localSnapshot(), null, 2) + "\n")
        Qt.callLater(root.startSyncScan)
    }

    function startSyncScan() {
        if (!syncConfigured()) {
            finishSyncRun()
            return
        }
        var script = "dir=$0; [[ -d \"$dir\" ]] || exit 0; shopt -s nullglob; for f in \"$dir\"/*.json; do [[ -f \"$f\" ]] || continue; printf '===%s===\\n' \"$f\"; cat \"$f\"; printf '\\n=== EOM ===\\n'; done"
        syncScanProcess.command = ["bash", "-c", script, root.syncEffectiveDir]
        syncScanProcess.running = true
    }

    function finishSyncRun() {
        if (syncRequestedWhileRunning && syncConfigured()) {
            syncRequestedWhileRunning = false
            scheduleSync()
        }
    }

    function expandPath(path) {
        var value = String(path || "").trim()
        if (value === "") return ""
        if (value === "~") return home
        if (value.indexOf("~/") === 0) return home + value.substring(1)
        if (value.indexOf("$HOME/") === 0) return home + value.substring(5)
        if (value.charAt(0) !== "/") return home + "/" + value
        return value
    }

    function safeDeviceId(raw) {
        var value = String(raw || "").trim()
        if (value === "") value = Quickshell.env("HOSTNAME") || root.detectedHostname || Quickshell.env("HOST") || Quickshell.env("USER") || "device"
        value = value.replace(/[^A-Za-z0-9_.-]+/g, "-").replace(/^[._-]+|[._-]+$/g, "")
        if (value === "") value = "device"
        return value.length > 80 ? value.substring(0, 80) : value
    }

    function safeSnapshotFileName(rawFileName, rawDeviceId) {
        var value = String(rawFileName || "").trim()
        if (value === "") value = safeDeviceId(rawDeviceId) + ".json"
        value = value.split("/").pop().replace(/[^A-Za-z0-9_.-]+/g, "-").replace(/^[._-]+|[._-]+$/g, "")
        if (value === "") value = safeDeviceId(rawDeviceId) + ".json"
        if (!/\.json$/i.test(value)) value += ".json"
        return value.length > 100 ? value.substring(0, 95) + ".json" : value
    }

    function parseSyncScanOutput(output) {
        var lines = String(output || "").split("\n")
        var snapshots = []
        var currentPath = ""
        var currentJson = []

        function flush() {
            if (currentPath === "") return
            var raw = currentJson.join("\n").trim()
            try {
                var parsed = JSON.parse(raw)
                if (parsed && parsed.providers) snapshots.push(parsed)
            } catch (e) {
                console.warn("agents/sync", "Ignoring bad snapshot", currentPath, e)
            }
            currentPath = ""
            currentJson = []
        }

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i]
            var start = line.match(/^===(.+)===$/)
            if (start && line !== "=== EOM ===") {
                flush()
                currentPath = start[1]
                currentJson = []
                continue
            }
            if (line === "=== EOM ===") {
                flush()
                continue
            }
            if (currentPath !== "") currentJson.push(line)
        }
        flush()

        aggregateData = aggregateSnapshots(snapshots)
        syncStatusText = ""
        syncRevision++
    }

    function cloneValue(value, fallback) {
        if (value === undefined || value === null) return fallback
        try {
            return JSON.parse(JSON.stringify(value))
        } catch (e) {
            return fallback
        }
    }

    function numberValue(value) {
        var n = Number(value || 0)
        return isFinite(n) ? Math.round(n) : 0
    }

    function dateString(date) {
        var y = date.getFullYear()
        var m = String(date.getMonth() + 1).padStart(2, "0")
        var d = String(date.getDate()).padStart(2, "0")
        return y + "-" + m + "-" + d
    }

    function recentDateStrings() {
        var result = []
        for (var offset = 6; offset >= 0; offset--) {
            var date = new Date()
            date.setDate(date.getDate() - offset)
            result.push(dateString(date))
        }
        return result
    }

    function emptyTokenBucket() {
        return { inputTokens: 0, outputTokens: 0, cacheReadInputTokens: 0, cacheCreationInputTokens: 0 }
    }

    function combineNumber(additive, current, value) {
        return additive ? numberValue(current) + numberValue(value) : Math.max(numberValue(current), numberValue(value))
    }

    function combineObjectNumbers(additive, target, source) {
        if (!source) return
        for (var key in source) target[key] = combineNumber(additive, target[key], source[key])
    }

    function aggregateSnapshots(snapshots) {
        var dates = recentDateStrings()
        var devices = {}
        var providers = {}

        function providerAcc(id) {
            if (providers[id]) return providers[id]
            var recentByDay = {}
            for (var d = 0; d < dates.length; d++) recentByDay[dates[d]] = 0
            providers[id] = {
                providerId: id,
                providerName: "",
                ready: false,
                hasLocalStats: false,
                hasPromptStats: false,
                todayPrompts: 0,
                todaySessions: 0,
                todayTotalTokens: 0,
                todayTokensByModel: ({}),
                recentByDay: recentByDay,
                totalPrompts: 0,
                totalSessions: 0,
                activeDays: 0,
                activeDates: ({}),
                modelUsage: ({}),
                devices: ({})
            }
            return providers[id]
        }

        for (var i = 0; i < snapshots.length; i++) {
            var snapshot = snapshots[i]
            var device = safeDeviceId(snapshot.deviceId || "device")
            devices[device] = true
            var snapshotProviders = snapshot.providers || {}
            for (var providerId in snapshotProviders) {
                var stats = snapshotProviders[providerId] || {}
                var acc = providerAcc(String(providerId))
                acc.devices[device] = true
                if (stats.providerName && acc.providerName === "") acc.providerName = String(stats.providerName)
                acc.ready = acc.ready || stats.ready === true
                acc.hasLocalStats = acc.hasLocalStats || stats.hasLocalStats !== false
                acc.hasPromptStats = acc.hasPromptStats || stats.hasPromptStats !== false
                var additive = String(stats.scope || "device") !== "account"
                acc.todayPrompts = combineNumber(additive, acc.todayPrompts, stats.todayPrompts)
                acc.todaySessions = combineNumber(additive, acc.todaySessions, stats.todaySessions)
                acc.todayTotalTokens = combineNumber(additive, acc.todayTotalTokens, stats.todayTotalTokens)
                acc.totalPrompts = combineNumber(additive, acc.totalPrompts, stats.totalPrompts)
                acc.totalSessions = combineNumber(additive, acc.totalSessions, stats.totalSessions)

                var activeDates = Array.isArray(stats.activeDates) ? stats.activeDates : []
                for (var ad = 0; ad < activeDates.length; ad++) acc.activeDates[String(activeDates[ad])] = true
                acc.activeDays = Math.max(acc.activeDays, numberValue(stats.activeDays))
                combineObjectNumbers(additive, acc.todayTokensByModel, stats.todayTokensByModel || {})

                var recent = Array.isArray(stats.recentDays) ? stats.recentDays : []
                for (var r = 0; r < recent.length; r++) {
                    var day = recent[r] || {}
                    var date = String(day.date || "")
                    if (acc.recentByDay[date] !== undefined)
                        acc.recentByDay[date] = combineNumber(additive, acc.recentByDay[date], day.messageCount)
                }

                var usage = stats.modelUsage || {}
                for (var modelId in usage) {
                    var bucket = acc.modelUsage[modelId]
                    if (!bucket) bucket = acc.modelUsage[modelId] = emptyTokenBucket()
                    combineObjectNumbers(additive, bucket, usage[modelId] || {})
                }
            }
        }

        var outProviders = {}
        for (var id in providers) {
            var acc = providers[id]
            var recentDays = []
            for (var di = 0; di < dates.length; di++) recentDays.push({ date: dates[di], messageCount: acc.recentByDay[dates[di]] || 0 })
            var providerDevices = Object.keys(acc.devices).sort()
            outProviders[id] = {
                providerId: acc.providerId,
                providerName: acc.providerName,
                ready: acc.ready || providerDevices.length > 0,
                hasLocalStats: acc.hasLocalStats,
                hasPromptStats: acc.hasPromptStats,
                todayPrompts: acc.todayPrompts,
                todaySessions: acc.todaySessions,
                todayTotalTokens: acc.todayTotalTokens,
                todayTokensByModel: acc.todayTokensByModel,
                recentDays: recentDays,
                totalPrompts: acc.totalPrompts,
                totalSessions: acc.totalSessions,
                activeDays: Math.max(acc.activeDays, Object.keys(acc.activeDates).length),
                modelUsage: acc.modelUsage,
                deviceCount: providerDevices.length,
                devices: providerDevices
            }
        }

        return {
            schemaVersion: 1,
            updatedAt: new Date().toISOString(),
            updatedAtMs: Date.now(),
            deviceCount: Object.keys(devices).length,
            devices: Object.keys(devices).sort(),
            providers: outProviders
        }
    }

    function providerSnapshot(record) {
        return {
            providerId: String(record.id),
            providerName: String(record.name || record.id),
            ready: record.ready === true,
            hasLocalStats: record.hasLocalStats !== false,
            hasPromptStats: record.hasPromptStats !== false,
            scope: String(record.scope || "device"),
            todayPrompts: numberValue(record.todayPrompts),
            todaySessions: numberValue(record.todaySessions),
            todayTotalTokens: numberValue(record.todayTotalTokens),
            todayTokensByModel: cloneValue(record.todayTokensByModel, ({})),
            recentDays: cloneValue(record.recentDays, []),
            totalPrompts: numberValue(record.totalPrompts),
            totalSessions: numberValue(record.totalSessions),
            activeDays: numberValue(record.activeDays),
            activeDates: cloneValue(record.activeDates, []),
            modelUsage: cloneValue(record.modelUsage, ({}))
        }
    }

    function localSnapshot() {
        var providerMap = {}
        for (var i = 0; i < agents.length; i++) {
            var record = agents[i] ? agents[i].record : null
            if (!record || !record.id) continue
            if (!providerEnabled(String(record.id))) continue
            providerMap[String(record.id)] = providerSnapshot(record)
        }
        return {
            schemaVersion: 1,
            deviceId: syncEffectiveDeviceId,
            updatedAt: new Date().toISOString(),
            providers: providerMap
        }
    }

    function syncedStatsFor(providerId) {
        var rev = syncRevision
        if (!syncConfigured() || !aggregateData || !aggregateData.providers) return null
        return aggregateData.providers[providerId] || null
    }

    // ---------------------------------------------------------------- format

    function windowIsLong(text) {
        var t = String(text || "").toLowerCase()
        return t.indexOf("week") >= 0 || t.indexOf("7-day") >= 0 || t.indexOf("seven") >= 0
            || t.indexOf("month") >= 0 || t.indexOf("30-day") >= 0 || t.indexOf("720h") >= 0
    }

    function windowSpanMs(label) {
        var text = String(label || "").toLowerCase()
        if (text.indexOf("month") >= 0 || text.indexOf("30-day") >= 0 || text.indexOf("720h") >= 0) return 30 * 24 * 3600 * 1000
        if (windowIsLong(text)) return 7 * 24 * 3600 * 1000
        var hours = text.match(/(\d+)\s*-?\s*h(?:our)?\b/)
        if (hours) return Number(hours[1]) * 3600 * 1000
        var minutes = text.match(/(\d+)\s*-?\s*m(?:in(?:ute)?s?)?\b/)
        if (minutes) return Number(minutes[1]) * 60 * 1000
        return 0
    }

    function windowTitle(label) {
        var text = String(label || "").toLowerCase()
        if (text.indexOf("month") >= 0 || text.indexOf("720h") >= 0) return "Monthly"
        if (windowIsLong(text)) return "Weekly"
        if (text.indexOf("session") >= 0 || windowSpanMs(label) > 0) return "Session"
        var plain = String(label || "").replace(/\s*\(.*\)\s*/, "").trim()
        return plain === "" ? "Limit" : plain
    }

    function limitWindow(label, percent, resetAt, title, extra) {
        extra = extra || ({})
        return {
            title: String(title || "") !== "" ? String(title) : windowTitle(label),
            subtitle: String(extra.subtitle || ""),
            detail: String(extra.detail || ""),
            group: String(extra.group || ""),
            percent: Number(percent),
            resetAt: String(resetAt || "")
        }
    }

    function limitWindows(p) {
        if (!p) return []
        var out = []
        var list = p.limits || []
        for (var i = 0; i < list.length; i++) {
            var entry = list[i] || {}
            var percent = Number(entry.percent)
            if (percent >= 0) out.push(limitWindow(entry.label, percent, entry.resetsAt, entry.title, {
                subtitle: entry.subtitle,
                detail: entry.detail,
                group: entry.group
            }))
        }
        return out
    }

    function bindingWindow(p) {
        var windows = limitWindows(p)
        var best = null
        for (var i = 0; i < windows.length; i++) {
            if (!best || windows[i].percent > best.percent) best = windows[i]
        }
        return best
    }

    function sessionWindow(p) {
        var windows = limitWindows(p)
        for (var i = 0; i < windows.length; i++) {
            var w = windows[i]
            var t = String(w.title || "").toLowerCase()
            var l = String(w.label || "").toLowerCase()
            if (t === "session" || l.indexOf("session") >= 0 || l.indexOf("5-hour") >= 0 || l.indexOf("5h") >= 0) {
                return w
            }
        }
        return null
    }

    function weeklyWindow(p) {
        var windows = limitWindows(p)
        for (var i = 0; i < windows.length; i++) {
            var w = windows[i]
            var t = String(w.title || "").toLowerCase()
            var l = String(w.label || "").toLowerCase()
            if (t === "weekly" || l.indexOf("week") >= 0 || l.indexOf("7-day") >= 0 || l.indexOf("7d") >= 0) {
                return w
            }
        }
        return null
    }

    function resetMsFor(w, nowMs) {
        if (!w || !w.resetAt) return -1
        var ms = new Date(w.resetAt).getTime()
        var now = (nowMs && nowMs > 0) ? nowMs : Date.now()
        return isFinite(ms) ? ms - now : -1
    }

    function formatDurationShort(ms) {
        if (!(ms > 0)) return ""
        var minutes = Math.floor(ms / 60000)
        var hours = Math.floor(minutes / 60)
        var days = Math.floor(hours / 24)
        if (days > 0) return days + "d"
        if (hours > 0) return hours + "h"
        return Math.max(1, minutes) + "m"
    }

    function formatDuration(ms) {
        if (!(ms > 0)) return "now"
        var minutes = Math.floor(ms / 60000)
        var hours = Math.floor(minutes / 60)
        var days = Math.floor(hours / 24)
        if (days > 0) return days + "d " + (hours % 24) + "h"
        if (hours > 0) return hours + "h " + (minutes % 60) + "m"
        return Math.max(1, minutes) + "m"
    }

    function currencyPrefix(currency) {
        var code = String(currency || "USD").toUpperCase()
        if (code === "USD") return "$"
        if (code === "EUR") return "€"
        if (code === "GBP") return "£"
        return code + " "
    }

    function formatMoney(value, currency) {
        var amount = Number(value)
        if (!isFinite(amount)) amount = 0
        return currencyPrefix(currency) + amount.toFixed(2)
    }

    function shortName(id) {
        return ({
            claude: "claude",
            codex: "codex",
            antigravity: "agy",
            cursor: "cursor",
            copilot: "copilot",
            grok: "grok",
            opencode: "oc"
        })[String(id || "")] || String(id || "")
    }

    function providerColor(id) {
        return ({
            claude: "#DE7356",
            codex: "#10A37F",
            antigravity: "#4285F4",
            cursor: "#38BDF8",
            copilot: "#A855F7",
            grok: "#8E8E93",
            opencode: "#6E6E73"
        })[id] || Theme.highlight
    }
}
