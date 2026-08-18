pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: theme

    property string mode: "dark"
    readonly property bool light: mode === "light"
    readonly property color background: light ? "#F1DBC2" : "#CC000000"
    readonly property color surface: light ? "#DFC8B1" : "#CC141414"
    readonly property color accent: light ? "#CCB7A0" : "#33FFFFFF"
    readonly property color text: light ? "#352B2D" : "#FFFFFF"
    readonly property color secondaryText: light ? "#44373A" : "#E0E0E0"
    readonly property color muted: light ? "#625458" : "#A0A0A0"
    readonly property color subtleMuted: light ? "#857974" : "#666666"
    readonly property color highlight: light ? "#4B3D43" : "#FFFFFF"
    readonly property color danger: light ? "#B5443C" : "#E06C5F"
    readonly property color success: light ? "#5F7D4A" : "#86A96F"
    readonly property string font: "JetBrains Mono Nerd Font"

    FileView {
        id: modeFile
        path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/quickshell/theme-mode"
        blockLoading: true
        watchChanges: true
        printErrors: false
        onLoaded: theme.mode = text().trim() === "light" ? "light" : "dark"
        onFileChanged: reload()
    }
}
