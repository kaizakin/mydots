import QtQuick
import QtQuick.Effects
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "Singletons" as Local

PanelWindow {
    id: root

    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: shown
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "ai-usage"

    property bool open: false
    property bool shown: false
    property int anchorX: 0

    readonly property var providers: Local.AgentUsage.enabledProviders
    readonly property int providerIndex: Local.AgentUsage.selectedProviderIndex
    readonly property var provider: Local.AgentUsage.selectedProvider

    property double nowMs: Date.now()
    readonly property var limits: Local.AgentUsage.limitWindows(provider)
    readonly property var headline: Local.AgentUsage.bindingWindow(provider)
    readonly property var balance: provider ? provider.balance : null
    readonly property bool balanceAlarming: !!balance && balance.funded > 0 && (balance.remaining / balance.funded <= 0.1)
    readonly property bool alarming: (!!headline && headline.percent >= 0.9) || balanceAlarming

    readonly property int minutesUntilUpdate: {
        var elapsed = Math.floor((nowMs - Local.AgentUsage.lastUpdatedMs) / 1000)
        var remainingSec = Math.max(0, (Local.AgentUsage.refreshIntervalSec) - elapsed)
        return Math.max(1, Math.ceil(remainingSec / 60))
    }

    function close() {
        open = false
        closeTimer.restart()
    }

    function toggle() {
        if (open) {
            close()
        } else {
            shown = true
            open = true
            nowMs = Date.now()
            Local.AgentUsage.refreshLimits()
        }
    }

    function selectProvider(index) {
        Local.AgentUsage.selectProvider(index)
    }

    function refresh(force) {
        Local.AgentUsage.refreshAll(force === true)
    }

    function resetMsFor(w) {
        if (!w || !w.resetAt) return -1
        var ms = new Date(w.resetAt).getTime()
        return isFinite(ms) ? ms - root.nowMs : -1
    }

    function heroMeta(p) {
        if (!p) return ""
        if (String(p.usageStatusText || "") !== "") return p.usageStatusText
        var tier = String(p.tierLabel || "")
        if (tier === "") return "Subscription"
        return tier.charAt(0).toUpperCase() + tier.slice(1)
    }

    function balanceDetailText(b) {
        if (!b || !(b.funded > 0)) return ""
        var text = Local.AgentUsage.formatMoney(b.spent, b.currency) + " spent of " + Local.AgentUsage.formatMoney(b.funded, b.currency) + " funded"
        if (b.estimated) text += " · estimated"
        return text
    }

    function footerText() {
        if (Local.AgentUsage.syncStatusText !== "") return Local.AgentUsage.syncStatusText
        if (provider && provider.syncEnabled && provider.syncDeviceCount > 0)
            return "Merged from " + provider.syncDeviceCount + " device" + (provider.syncDeviceCount === 1 ? "" : "s")
        return ""
    }

    Timer { id: closeTimer; interval: 180; onTriggered: root.shown = false }
    Timer { interval: 15000; running: root.shown; repeat: true; onTriggered: root.nowMs = Date.now() }
    Process { id: settingsProcess }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    FocusScope {
        id: scope
        anchors.fill: parent
        focus: root.open

        Keys.onEscapePressed: root.close()
        Keys.onLeftPressed: root.selectProvider(root.providerIndex - 1)
        Keys.onRightPressed: root.selectProvider(root.providerIndex + 1)
        Keys.onReturnPressed: root.refresh(true)
        Keys.onPressed: event => {
            if (event.key === Qt.Key_H) {
                root.selectProvider(root.providerIndex - 1)
                event.accepted = true
            } else if (event.key === Qt.Key_L) {
                root.selectProvider(root.providerIndex + 1)
                event.accepted = true
            } else if (event.key === Qt.Key_R) {
                root.refresh(true)
                event.accepted = true
            } else if (event.key === Qt.Key_J) {
                flick.contentY = Math.min(flick.contentHeight - flick.height, flick.contentY + 40)
                event.accepted = true
            } else if (event.key === Qt.Key_K) {
                flick.contentY = Math.max(0, flick.contentY - 40)
                event.accepted = true
            }
        }

        Rectangle {
            id: card
            width: root.open ? 380 : 30
            height: root.open ? Math.min(680, contentLayout.implicitHeight + 72) : 30
            x: Math.max(12, Math.min(parent.width - width - 12, root.anchorX - width / 2))
            y: 46
            radius: root.open ? 22 : 15
            color: Local.Theme.light ? "#F5E6D3" : "#E6000000"
            border.color: Local.Theme.accent
            border.width: 1
            clip: true

            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            MouseArea {
                anchors.fill: parent
                // absorb clicks inside panel
            }

            Flickable {
                id: flick
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: footerItem.top
                anchors.margins: 14
                contentWidth: width
                contentHeight: contentLayout.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                Column {
                    id: contentLayout
                    width: parent.width
                    spacing: 12

                    // ---------- Hero: Mark · Name · Plan ----------
                    Item {
                        id: heroItem
                        width: parent.width
                        height: 46

                        Item {
                            id: heroIconContainer
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 32
                            height: 32

                            Image {
                                id: heroIcon
                                anchors.fill: parent
                                source: root.provider ? "assets/" + root.provider.providerId + ".svg" : ""
                                sourceSize: Qt.size(width, height)
                                fillMode: Image.PreserveAspectFit
                                visible: false
                            }

                            MultiEffect {
                                anchors.fill: parent
                                source: heroIcon
                                brightness: 1
                                colorization: 1
                                colorizationColor: root.alarming ? Local.Theme.danger : Local.Theme.text
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: heroIcon.status !== Image.Ready
                                text: "󱚣"
                                font.family: Local.Theme.font
                                font.pixelSize: 22
                                color: root.alarming ? Local.Theme.danger : Local.Theme.text
                            }
                        }

                        Column {
                            anchors.left: heroIconContainer.right
                            anchors.leftMargin: 12
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                text: root.provider ? root.provider.providerName : "AI Agents"
                                color: Local.Theme.text
                                font.family: Local.Theme.font
                                font.pixelSize: 15
                                font.bold: true
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: root.heroMeta(root.provider)
                                color: root.alarming ? Local.Theme.danger : Local.Theme.muted
                                font.family: Local.Theme.font
                                font.pixelSize: 11
                                font.bold: root.alarming
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }
                    }

                    // Empty state if no agents have data
                    Text {
                        visible: root.providers.length === 0
                        width: parent.width
                        topPadding: 16
                        bottomPadding: 16
                        text: "No active AI agent subscriptions found.\nUsage records appear here automatically when agents run."
                        color: Local.Theme.muted
                        font.family: Local.Theme.font
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }

                    // ---------- Subscription Switcher Chips ----------
                    Row {
                        id: chipRow
                        visible: root.providers.length > 1
                        width: parent.width
                        spacing: 6

                        readonly property real chipWidth: (width - (spacing * (root.providers.length - 1))) / root.providers.length

                        Repeater {
                            model: root.providers

                            delegate: Rectangle {
                                id: chip
                                required property var modelData
                                required property int index
                                width: chipRow.chipWidth
                                height: 28
                                radius: 8
                                color: index === root.providerIndex ? Local.Theme.surface : "transparent"
                                border.color: index === root.providerIndex ? Local.Theme.highlight : Local.Theme.accent
                                border.width: 1

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 5

                                    Item {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 12
                                        height: 12

                                        Image {
                                            id: chipIcon
                                            anchors.fill: parent
                                            source: "assets/" + chip.modelData.providerId + ".svg"
                                            sourceSize: Qt.size(12, 12)
                                            fillMode: Image.PreserveAspectFit
                                            visible: false
                                        }

                                        MultiEffect {
                                            anchors.fill: parent
                                            source: chipIcon
                                            brightness: 1
                                            colorization: 1
                                            colorizationColor: Local.Theme.text
                                        }
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: chip.modelData.shortName || chip.modelData.providerName
                                        color: index === root.providerIndex ? Local.Theme.text : Local.Theme.muted
                                        font.family: Local.Theme.font
                                        font.pixelSize: 11
                                        font.bold: index === root.providerIndex
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.selectProvider(chip.index)
                                }
                            }
                        }
                    }

                    // ---------- Status / Auth Alert Banner ----------
                    Rectangle {
                        visible: !!root.provider
                            && String(root.provider.usageStatusText || root.provider.authHelpText || "") !== ""
                            && root.limits.length === 0
                            && !root.balance
                        width: parent.width
                        implicitHeight: statusCol.implicitHeight + 16
                        radius: 10
                        color: Local.Theme.light ? "#FEE2E2" : "#337F1D1D"
                        border.color: Local.Theme.danger
                        border.width: 1

                        Column {
                            id: statusCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: 10
                            spacing: 3

                            Text {
                                visible: root.provider && String(root.provider.usageStatusText || "") !== ""
                                text: root.provider ? String(root.provider.usageStatusText) : ""
                                color: Local.Theme.danger
                                font.family: Local.Theme.font
                                font.pixelSize: 11
                                font.bold: true
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }

                            Text {
                                visible: root.provider && String(root.provider.authHelpText || "") !== ""
                                text: root.provider ? String(root.provider.authHelpText) : ""
                                color: Local.Theme.text
                                font.family: Local.Theme.font
                                font.pixelSize: 10
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }
                        }
                    }

                    // ---------- Prepaid Balance Section ----------
                    Rectangle {
                        id: balanceBox
                        visible: !!root.balance && !(root.provider && root.provider.providerId === "cursor")
                        width: parent.width
                        implicitHeight: balanceCol.implicitHeight + 20
                        radius: 12
                        color: Local.Theme.light ? "#DFC8B1" : "#E6141414"
                        border.color: Local.Theme.accent
                        border.width: 1

                        readonly property real ratio: root.balance && root.balance.funded > 0
                            ? Math.max(0, Math.min(1, root.balance.remaining / root.balance.funded))
                            : -1

                        Column {
                            id: balanceCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 10
                            spacing: 8

                            Text {
                                text: "BALANCE"
                                color: Local.Theme.muted
                                font.family: Local.Theme.font
                                font.pixelSize: 10
                                font.bold: true
                            }

                            Item {
                                width: parent.width
                                height: 16

                                Text {
                                    text: "Prepaid credits"
                                    color: Local.Theme.text
                                    font.family: Local.Theme.font
                                    font.pixelSize: 12
                                    font.bold: true
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: root.balance ? Local.AgentUsage.formatMoney(root.balance.remaining, root.balance.currency) : ""
                                    color: root.balanceAlarming ? Local.Theme.danger : Local.Theme.text
                                    font.family: Local.Theme.font
                                    font.pixelSize: 13
                                    font.bold: true
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            // Meter progress bar
                            Rectangle {
                                visible: balanceBox.ratio >= 0
                                width: parent.width
                                height: 6
                                radius: 3
                                color: Local.Theme.accent

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: parent.width * balanceBox.ratio
                                    radius: 3
                                    color: root.balanceAlarming ? Local.Theme.danger : Local.Theme.highlight

                                    Behavior on width {
                                        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                                    }
                                }
                            }

                            Text {
                                visible: text.length > 0
                                width: parent.width
                                text: root.balanceDetailText(root.balance)
                                color: Local.Theme.muted
                                font.family: Local.Theme.font
                                font.pixelSize: 10
                            }
                        }
                    }

                    // ---------- Rate Limits Section ----------
                    Rectangle {
                        id: limitsBox
                        visible: root.limits.length > 0
                        width: parent.width
                        implicitHeight: limitsCol.implicitHeight + 20
                        radius: 12
                        color: Local.Theme.light ? "#DFC8B1" : "#E6141414"
                        border.color: Local.Theme.accent
                        border.width: 1

                        Column {
                            id: limitsCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 10
                            spacing: 10

                            Text {
                                text: {
                                    if (!root.limits.length) return "LIMITS"
                                    var group = String(root.limits[0].group || "")
                                    for (var i = 1; i < root.limits.length; i++) {
                                        if (String(root.limits[i].group || "") !== group) return "LIMITS"
                                    }
                                    return group !== "" ? group : "LIMITS"
                                }
                                color: Local.Theme.muted
                                font.family: Local.Theme.font
                                font.pixelSize: 10
                                font.bold: true
                            }

                            Repeater {
                                model: root.limits

                                delegate: Column {
                                    id: limitRow
                                    required property var modelData
                                    width: limitsCol.width
                                    spacing: 5

                                    readonly property bool rowAlarming: limitRow.modelData && limitRow.modelData.percent >= 0.9
                                    readonly property double remainingMs: root.resetMsFor(limitRow.modelData)

                                    Item {
                                        width: parent.width
                                        height: 16

                                        Text {
                                            anchors.left: parent.left
                                            anchors.right: limitPct.left
                                            anchors.rightMargin: 8
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: limitRow.modelData ? limitRow.modelData.title : "Limit"
                                            color: Local.Theme.text
                                            font.family: Local.Theme.font
                                            font.pixelSize: 12
                                            font.bold: true
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            id: limitPct
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: limitRow.modelData && limitRow.modelData.percent >= 0
                                                ? Math.round(limitRow.modelData.percent * 100) + "% used"
                                                : "—"
                                            color: limitRow.rowAlarming ? Local.Theme.danger : Local.Theme.text
                                            font.family: Local.Theme.font
                                            font.pixelSize: 12
                                            font.bold: true
                                        }
                                    }

                                    Text {
                                        visible: limitRow.modelData && String(limitRow.modelData.subtitle || "") !== ""
                                        width: parent.width
                                        text: limitRow.modelData ? String(limitRow.modelData.subtitle) : ""
                                        color: Local.Theme.muted
                                        font.family: Local.Theme.font
                                        font.pixelSize: 10
                                        wrapMode: Text.WordWrap
                                    }

                                    // Meter track
                                    Rectangle {
                                        width: parent.width
                                        height: 6
                                        radius: 3
                                        color: Local.Theme.accent

                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            width: parent.width * Math.max(0, Math.min(1, limitRow.modelData ? limitRow.modelData.percent : 0))
                                            radius: 3
                                            color: limitRow.rowAlarming ? Local.Theme.danger : Local.Theme.highlight

                                            Behavior on width {
                                                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                                            }
                                        }
                                    }

                                    Text {
                                        visible: {
                                            var detail = limitRow.modelData ? String(limitRow.modelData.detail || "") : ""
                                            return detail !== "" || limitRow.remainingMs > 0
                                        }
                                        width: parent.width
                                        wrapMode: Text.WordWrap
                                        text: {
                                            var detail = limitRow.modelData ? String(limitRow.modelData.detail || "") : ""
                                            if (detail !== "") return detail
                                            return "Resets in " + Local.AgentUsage.formatDuration(limitRow.remainingMs)
                                        }
                                        color: Local.Theme.muted
                                        font.family: Local.Theme.font
                                        font.pixelSize: 10
                                    }
                                }
                            }
                        }
                    }

                    // Sync summary if multiple devices merged
                    Text {
                        visible: root.footerText() !== ""
                        width: parent.width
                        text: "󰁥 " + root.footerText()
                        color: Local.Theme.muted
                        font.family: Local.Theme.font
                        font.pixelSize: 10
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                }
            }

            // ---------- Footer Bottom Bar ----------
            Item {
                id: footerItem
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 38

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Local.Theme.accent
                }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Local.AgentUsage.updating ? "Updating…" : "Next update in " + root.minutesUntilUpdate + "m"
                        color: refreshBtnMouse.containsMouse ? Local.Theme.text : Local.Theme.muted
                        font.family: Local.Theme.font
                        font.pixelSize: 11
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    // Rescan button
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 76
                        height: 24
                        radius: 8
                        color: refreshBtnMouse.containsMouse ? Local.Theme.highlight : Local.Theme.surface
                        border.color: Local.Theme.accent
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "󰑐 Rescan"
                            color: refreshBtnMouse.containsMouse ? Local.Theme.background : Local.Theme.text
                            font.family: Local.Theme.font
                            font.pixelSize: 10
                            font.bold: true
                        }

                        MouseArea {
                            id: refreshBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.refresh(true)
                        }
                    }

                    // Settings shortcut button
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 24
                        height: 24
                        radius: 12
                        color: settingsBtnMouse.containsMouse ? Local.Theme.highlight : Local.Theme.surface
                        border.color: Local.Theme.accent
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "•••"
                            color: settingsBtnMouse.containsMouse ? Local.Theme.background : Local.Theme.text
                            font.family: Local.Theme.font
                            font.pixelSize: 10
                            font.bold: true
                        }

                        MouseArea {
                            id: settingsBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.close()
                                settingsProcess.command = ["qs", "ipc", "call", "pillSettings", "open", "ai-usage"]
                                settingsProcess.running = true
                            }
                        }
                    }
                }
            }
        }
    }
}
