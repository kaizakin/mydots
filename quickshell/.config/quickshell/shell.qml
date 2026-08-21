//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import QtQuick
import "pill" as Pill

ShellRoot {
    id: root

    property bool powerMenuLoaded: false
    property bool settingsLoaded: false
    property int aiUsageAnchorX: 0
    property string settingsPage: "bar"

    Pill.Bar {
        id: bar
        onTrayMenuRequested: (item, anchorX) => trayMenu.openMenu(item, anchorX)
    }
    Pill.Pill {}
    Pill.AiUsagePanel { id: aiUsagePanel; anchorX: root.aiUsageAnchorX }
    Pill.TrayMenu {
        id: trayMenu
        // @note right click while open: switch to the tray item under the cursor, or close
        onSwitchRequested: globalX => {
            const target = bar.trayItemAt(globalX)
            if (target && target.modelData !== trayMenu.trayItem) {
                const pos = target.mapToItem(null, target.width / 2, 0)
                trayMenu.openMenu(target.modelData, Math.round(pos.x))
            } else {
                trayMenu.close()
            }
        }
    }
    Pill.KeystrokeOverlay {}

    IpcHandler {
        target: "aiUsage"
        function toggle(anchorX: int): void {
            root.aiUsageAnchorX = anchorX
            aiUsagePanel.anchorX = anchorX
            aiUsagePanel.toggle()
        }
        function open(anchorX: int): void {
            root.aiUsageAnchorX = anchorX
            aiUsagePanel.anchorX = anchorX
            if (!aiUsagePanel.open) aiUsagePanel.toggle()
        }
        function close(): void { aiUsagePanel.close() }
        function refresh(): void { aiUsagePanel.refresh(true) }
        function next(): void { aiUsagePanel.selectProvider(aiUsagePanel.providerIndex + 1) }
    }

    IpcHandler {
        target: "agents"
        function toggle(): void { aiUsagePanel.toggle() }
        function open(): void { if (!aiUsagePanel.open) aiUsagePanel.toggle() }
        function close(): void { aiUsagePanel.close() }
        function refresh(): void { aiUsagePanel.refresh(true) }
        function next(): void { aiUsagePanel.selectProvider(aiUsagePanel.providerIndex + 1) }
    }

    Loader {
        id: settingsLoader
        active: root.settingsLoaded
        sourceComponent: Component {
            Pill.SettingsWindow {
                page: root.settingsPage
                onDismissed: {
                    root.settingsPage = "bar"
                    root.settingsLoaded = false
                }
            }
        }
    }

    Loader {
        id: powerMenuLoader
        active: root.powerMenuLoaded
        sourceComponent: Component {
            Pill.PowerMenu { onDismissed: root.powerMenuLoaded = false }
        }
    }

    IpcHandler {
        target: "powerMenu"
        function toggle(): void {
            if (powerMenuLoader.item)
                powerMenuLoader.item.toggle()
            else {
                root.powerMenuLoaded = true
                powerMenuOpenTimer.restart()
            }
        }
    }

    Timer {
        id: powerMenuOpenTimer
        interval: 0
        onTriggered: powerMenuLoader.item?.toggle()
    }

    IpcHandler {
        target: "pillSettings"
        function toggle(): void {
            if (settingsLoader.item)
                settingsLoader.item.close()
            else {
                root.settingsPage = "bar"
                root.settingsLoaded = true
            }
        }
        function open(page: string): void {
            root.settingsPage = page
            if (settingsLoader.item) {
                settingsLoader.item.page = page
                settingsLoader.item.open = true
            } else {
                root.settingsLoaded = true
            }
        }
    }
}
