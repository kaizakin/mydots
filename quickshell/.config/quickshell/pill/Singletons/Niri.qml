pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: niri

    property var workspaces: []
    property var windows: []
    property int focusedWorkspaceId: -1
    property int focusedWorkspaceIdx: 1

    function focusWorkspace(idxOrName) {
        focusProcess.command = ["niri", "msg", "action", "focus-workspace", String(idxOrName)]
        focusProcess.running = true
    }

    function isWorkspaceFocused(idx) {
        return focusedWorkspaceIdx === idx
    }

    function handleEvent(data) {
        try {
            const ev = JSON.parse(data)
            if (ev.WorkspacesChanged) {
                const ws = ev.WorkspacesChanged.workspaces || []
                ws.sort((a, b) => (a.idx || 0) - (b.idx || 0))
                workspaces = ws
                const active = ws.find(w => w.is_focused || w.is_active)
                if (active) {
                    focusedWorkspaceId = active.id
                    focusedWorkspaceIdx = active.idx
                }
            } else if (ev.WorkspaceActivated) {
                focusedWorkspaceId = ev.WorkspaceActivated.id
                const found = workspaces.find(w => w.id === ev.WorkspaceActivated.id)
                if (found) focusedWorkspaceIdx = found.idx
            }
        } catch (e) {}
    }

    Process {
        id: eventProcess
        command: ["niri", "msg", "--json", "event-stream"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                if (data && data.trim()) {
                    niri.handleEvent(data.trim())
                }
            }
        }

        onExited: {
            restartTimer.restart()
        }
    }

    Timer {
        id: restartTimer
        interval: 1000
        onTriggered: eventProcess.running = true
    }

    Process {
        id: focusProcess
    }
}
