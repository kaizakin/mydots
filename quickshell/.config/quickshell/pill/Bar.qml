import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Widgets
import "Singletons"
import "components" as Components

PanelWindow {
    id: root

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 38
    color: "transparent"

    property int pillHeight: 30
    property date now: new Date()
    property string brightness: "--"
    signal trayMenuRequested(var item, int anchorX)
    function horizontalBatteryIcon(percentage) {
        if (percentage > 0.8) return ""
        if (percentage > 0.6) return ""
        if (percentage > 0.4) return ""
        if (percentage > 0.15) return ""
        return ""
    }

    // @note find the tray item under a global x so the tray menu can switch targets
    function trayItemAt(globalX) {
        for (let i = 0; i < trayRow.children.length; i++) {
            const child = trayRow.children[i]
            const pos = child.mapToItem(null, 0, 0)
            if (globalX >= pos.x && globalX <= pos.x + child.width)
                return child
        }
        return null
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Process {
        id: brightnessProcess
        command: ["brightnessctl", "-m"]

        stdout: StdioCollector {
            onStreamFinished: {
                const fields = this.text.trim().split(",")
                root.brightness = fields.length > 3 ? fields[3] : "--"
            }
        }
    }

    Timer {
        interval: Settings.showSeconds ? 1000 : 10000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    property string wifiName: ""
    property string bluetoothDevice: ""
    property bool bluetoothPowered: true

    Process {
        id: netStatusProcess
        command: ["sh", "-c", "wifi=$(nmcli -t -f NAME,TYPE c show --active 2>/dev/null | grep -E ':802-11-wireless|:gsm|:cdma|:802-3-ethernet' | head -n 1 | cut -d: -f1); bt=$(bluetoothctl devices Connected 2>/dev/null | head -n 1 | cut -d ' ' -f 3-); bt_powered=$(bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo '1' || echo '0'); printf 'wifi=%s\\nbt=%s\\nbt_powered=%s\\n' \"$wifi\" \"$bt\" \"$bt_powered\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n")
                for (let i = 0; i < lines.length; i++) {
                    const pair = lines[i].split("=")
                    if (pair[0] === "wifi") root.wifiName = pair.slice(1).join("=")
                    if (pair[0] === "bt") root.bluetoothDevice = pair.slice(1).join("=")
                    if (pair[0] === "bt_powered") root.bluetoothPowered = pair[1] === "1"
                }
            }
        }
    }

    Process {
        id: wlctlProcess
        command: ["kitty", "--class=local.wlctl", "-e", "wlctl"]
        onExited: netStatusProcess.running = true
    }

    Process {
        id: bluetuiProcess
        command: ["kitty", "--class=local.bluetui", "-e", "bluetui"]
        onExited: netStatusProcess.running = true
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: brightnessProcess.running = true
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: netStatusProcess.running = true
    }

    component Pill: Rectangle {
        radius: Settings.barRadius
        color: Theme.surface
        height: root.pillHeight
    }




    Item {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12

        Row {
            id: leftContent
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: 8
            spacing: 8

            Pill {
                visible: Settings.showTray
                width: trayRow.width + 20

                Row {
                    id: trayRow
                    anchors.centerIn: parent
                    spacing: 5

                    Repeater {
                        model: SystemTray.items

                        delegate: Item {
                            id: trayItem
                            required property var modelData
                            width: 16
                            height: 16

                            IconImage {
                                anchors.fill: parent
                                source: modelData.icon
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton) {
                                        // @note open the themed tray menu below the icon; fall back to secondary activate
                                        if (modelData.hasMenu) {
                                            const pos = trayItem.mapToItem(null, trayItem.width / 2, 0)
                                            root.trayMenuRequested(modelData, Math.round(pos.x))
                                        } else {
                                            modelData.secondaryActivate()
                                        }
                                    } else {
                                        modelData.activate()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Pill {
                visible: Settings.showWorkspaces
                width: workspaceRow.width + 12

                Row {
                    id: workspaceRow
                    anchors.centerIn: parent
                    spacing: 3

                    Repeater {
                        model: Math.max(5, Niri.workspaces.length > 0 ? (Niri.workspaces[Niri.workspaces.length - 1].idx || 5) : 5)

                        delegate: Rectangle {
                            id: workspaceButton
                            width: 20
                            height: 20
                            radius: height / 2
                            property int workspace: index + 1
                            property bool focused: Niri.focusedWorkspaceIdx === workspace
                            color: focused ? Theme.highlight : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: parent.workspace
                                color: parent.focused ? Theme.background : Theme.secondaryText
                                font.family: Theme.font
                                font.pixelSize: 11
                                font.bold: parent.focused
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: Niri.focusWorkspace(workspaceButton.workspace)
                            }
                        }
                    }
                }
            }
        }

        Row {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 8
            spacing: 8



            Pill {
                id: aiUsagePill
                visible: Settings.showAiUsage
                width: aiUsageContent.implicitWidth + 20
                color: aiMouse.containsMouse ? Theme.background : Theme.surface
                border.color: aiMouse.containsMouse ? Theme.highlight : Theme.accent
                border.width: 1

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                Components.AiUsage {
                    id: aiUsageContent
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: aiMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.MiddleButton) {
                            AgentUsage.selectProvider(AgentUsage.selectedProviderIndex + 1)
                        } else {
                            const pos = aiUsagePill.mapToItem(null, aiUsagePill.width / 2, 0)
                            aiProc.command = ["qs", "ipc", "call", "aiUsage", "toggle", Math.round(pos.x)]
                            aiProc.running = true
                        }
                    }
                }

                Process { id: aiProc }
            }

            Pill {
                id: netBtPill
                width: netBtRow.width + 20

                Row {
                    id: netBtRow
                    anchors.centerIn: parent
                    spacing: 12

                    Item {
                        id: btItem
                        width: btRow.width
                        height: 20
                        anchors.verticalCenter: parent.verticalCenter

                        Row {
                            id: btRow
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 5

                            Text {
                                text: !root.bluetoothPowered ? "󰂲" : (root.bluetoothDevice !== "" ? "󰂱" : "󰂯")
                                color: btMouse.containsMouse ? Theme.highlight : (!root.bluetoothPowered ? Theme.muted : (root.bluetoothDevice !== "" ? Theme.text : Theme.secondaryText))
                                font.family: Theme.font
                                font.pixelSize: 13
                            }

                            Text {
                                text: root.bluetoothDevice !== "" ? (root.bluetoothDevice.length > 12 ? root.bluetoothDevice.slice(0, 11) + "…" : root.bluetoothDevice) : "--"
                                color: btMouse.containsMouse ? Theme.highlight : (root.bluetoothDevice !== "" ? Theme.secondaryText : Theme.muted)
                                font.family: Theme.font
                                font.pixelSize: 12
                            }
                        }

                        MouseArea {
                            id: btMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: bluetuiProcess.running = true
                        }
                    }

                    Item {
                        id: wifiItem
                        width: wifiRow.width
                        height: 20
                        anchors.verticalCenter: parent.verticalCenter

                        Row {
                            id: wifiRow
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 5

                            Text {
                                text: root.wifiName !== "" ? "󰤨" : "󰖪"
                                color: wifiMouse.containsMouse ? Theme.highlight : (root.wifiName !== "" ? Theme.text : Theme.muted)
                                font.family: Theme.font
                                font.pixelSize: 13
                            }

                            Text {
                                text: root.wifiName !== "" ? (root.wifiName.length > 14 ? root.wifiName.slice(0, 13) + "…" : root.wifiName) : "--"
                                color: wifiMouse.containsMouse ? Theme.highlight : (root.wifiName !== "" ? Theme.secondaryText : Theme.muted)
                                font.family: Theme.font
                                font.pixelSize: 12
                            }
                        }

                        MouseArea {
                            id: wifiMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: wlctlProcess.running = true
                        }
                    }
                }
            }

            Pill {
                visible: Settings.showDate || Settings.showTime
                width: clockRow.width + 22

                Row {
                    id: clockRow
                    anchors.centerIn: parent
                    spacing: 10

                    Text {
                        visible: Settings.showDate
                        text: "󰃭 " + Qt.formatDate(root.now, "dd:MM")
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 12
                    }

                    Text {
                        visible: Settings.showTime
                        text: "󰥔 " + Qt.formatTime(root.now, Settings.showSeconds ? "hh:mm:ss AP" : "hh:mm AP")
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 12
                        font.bold: true
                    }
                }
            }

            Pill {
                visible: Settings.showAudio || Settings.showBrightness || (Settings.showBattery && UPower.displayDevice !== null)
                width: systemRow.width + 22

                Row {
                    id: systemRow
                    anchors.centerIn: parent
                    spacing: 12

                    Text {
                        visible: Settings.showAudio
                        text: {
                            const sink = Pipewire.defaultAudioSink
                            if (!sink || !sink.audio || sink.audio.muted) return "󰝟"
                            const icon = sink.audio.volume > 0.66 ? "󰕾" : sink.audio.volume > 0.33 ? "󰖀" : "󰕿"
                            return icon + " " + Math.round(sink.audio.volume * 100) + "%"
                        }
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 12

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                const sink = Pipewire.defaultAudioSink
                                if (sink && sink.audio) sink.audio.muted = !sink.audio.muted
                            }
                            onWheel: wheel => {
                                const sink = Pipewire.defaultAudioSink
                                if (!sink || !sink.audio || wheel.angleDelta.y === 0) return
                                const change = wheel.angleDelta.y > 0 ? 0.03 : -0.03
                                sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + change))
                                wheel.accepted = true
                            }
                        }
                    }

                    Text {
                        visible: Settings.showBrightness
                        text: "󰃠 " + root.brightness
                        color: Theme.secondaryText
                        font.family: Theme.font
                        font.pixelSize: 12

                        Process {
                            id: brightnessChange
                            onExited: brightnessProcess.running = true
                        }

                        MouseArea {
                            anchors.fill: parent
                            onWheel: wheel => {
                                if (wheel.angleDelta.y === 0) return
                                brightnessChange.command = ["brightnessctl", "set", wheel.angleDelta.y > 0 ? "+3%" : "3%-"]
                                brightnessChange.running = true
                                wheel.accepted = true
                            }
                        }
                    }

                    Row {
                        id: batteryItem
                        visible: Settings.showBattery && UPower.displayDevice !== null
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter

                        readonly property real percentage: UPower.displayDevice?.percentage ?? 0
                        readonly property bool isCharging: {
                            const dev = UPower.displayDevice
                            if (!dev) return false
                            return dev.state === UPowerDeviceState.Charging || dev.state === UPowerDeviceState.FullyCharged || dev.state === UPowerDeviceState.PendingCharge || dev.state == 1 || dev.state == 4 || dev.state == 5
                        }
                        readonly property color batteryColor: isCharging ? (Theme.light ? "#16a34a" : "#4ade80") : (percentage <= 0.2 ? Theme.danger : Theme.text)

                        Text {
                            visible: batteryItem.isCharging
                            text: "󱐋"
                            color: batteryItem.batteryColor
                            font.family: Theme.font
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: root.horizontalBatteryIcon(batteryItem.percentage)
                            color: batteryItem.batteryColor
                            font.family: Theme.font
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: Math.round(batteryItem.percentage * 100) + "%"
                            color: batteryItem.batteryColor
                            font.family: Theme.font
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }
}
