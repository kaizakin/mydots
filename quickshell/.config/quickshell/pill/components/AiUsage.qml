import QtQuick
import QtQuick.Effects
import Quickshell.Io
import Quickshell
import "../Singletons" as Local

Item {
    id: root

    readonly property var providers: {
        var all = Local.AgentUsage.enabledProviders
        var barAllowed = Local.Settings.aiUsageBarProviders || ""
        if (barAllowed === "") return all
        var list = barAllowed.split(",").map(s => s.trim()).filter(s => s.length > 0)
        if (list.length === 0) return all
        return all.filter(p => list.includes(p.providerId))
    }
    readonly property var currentProvider: Local.AgentUsage.selectedProvider

    readonly property var headline: Local.AgentUsage.bindingWindow(currentProvider)
    readonly property var balance: currentProvider ? currentProvider.balance : null
    readonly property bool balanceAlarming: !!balance && balance.funded > 0 && (balance.remaining / balance.funded <= 0.1)
    readonly property bool alarming: (!!headline && headline.percent >= 0.9) || balanceAlarming

    visible: Local.Settings.showAiUsage
    implicitWidth: visible ? Math.max(32, (providers.length > 0 ? row.implicitWidth : emptyRow.implicitWidth)) : 0
    implicitHeight: 20

    // Display when agents have data
    Row {
        id: row
        visible: root.providers.length > 0
        anchors.centerIn: parent
        spacing: 8

        Repeater {
            model: root.providers

            delegate: Row {
                id: providerItem
                required property var modelData
                required property int index

                readonly property var pHeadline: Local.AgentUsage.bindingWindow(modelData)
                readonly property var pSession: Local.AgentUsage.sessionWindow(modelData)
                readonly property var pBalance: modelData.balance
                readonly property var pLimit: (modelData.providerId === "claude" && pSession && pSession.percent >= 0) ? pSession : pHeadline
                readonly property bool pAlarming: (!!pLimit && pLimit.percent >= 0.9) || (!!pBalance && pBalance.funded > 0 && pBalance.remaining / pBalance.funded <= 0.1)
                readonly property bool isSelected: index === Local.AgentUsage.selectedProviderIndex

                spacing: 4
                opacity: (root.providers.length === 1 || isSelected) ? 1.0 : 0.65

                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 15
                    height: 15
                    implicitWidth: 15
                    implicitHeight: 15

                    Image {
                        id: aiIcon
                        anchors.fill: parent
                        source: "../assets/" + providerItem.modelData.providerId + ".svg"
                        sourceSize: Qt.size(width, height)
                        fillMode: Image.PreserveAspectFit
                        visible: false
                    }

                    MultiEffect {
                        anchors.fill: parent
                        source: aiIcon
                        brightness: 1
                        colorization: 1
                        colorizationColor: providerItem.pAlarming ? Local.Theme.danger : (providerItem.isSelected ? Local.Theme.text : Local.Theme.secondaryText)
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: aiIcon.status !== Image.Ready
                        text: "󱚣"
                        font.family: Local.Theme.font
                        font.pixelSize: 12
                        color: providerItem.pAlarming ? Local.Theme.danger : Local.Theme.secondaryText
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        if (providerItem.pLimit && providerItem.pLimit.percent >= 0) {
                            return Math.round(providerItem.pLimit.percent * 100) + "%"
                        }
                        if (providerItem.pBalance) {
                            return Local.AgentUsage.formatMoney(providerItem.pBalance.remaining, providerItem.pBalance.currency)
                        }
                        if (providerItem.modelData.tierLabel) {
                            return providerItem.modelData.tierLabel
                        }
                        return ""
                    }
                    visible: text.length > 0
                    color: providerItem.pAlarming ? Local.Theme.danger : (providerItem.isSelected ? Local.Theme.text : Local.Theme.secondaryText)
                    font.family: Local.Theme.font
                    font.pixelSize: 12
                    font.bold: providerItem.isSelected
                }
            }
        }
    }

    // Fallback display when no agent has usage yet
    Row {
        id: emptyRow
        visible: root.providers.length === 0
        anchors.centerIn: parent
        spacing: 5

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "󱚣"
            font.family: Local.Theme.font
            font.pixelSize: 13
            color: Local.Theme.secondaryText
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "AI"
            font.family: Local.Theme.font
            font.pixelSize: 12
            color: Local.Theme.secondaryText
        }
    }
}
