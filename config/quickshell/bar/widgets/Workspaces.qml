import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../theme"
import "../../ui"

Item {
    id: root

    Theme {
        id: theme
    }

    function workspaceById(id) {
        var values = Hyprland.workspaces.values

        for (var i = 0; i < values.length; i++) {
            if (values[i].id === id)
                return values[i]
        }

        return null
    }

    function workspaceIds() {
        var ids = [1, 2, 3, 4, 5]
        var values = Hyprland.workspaces.values

        for (var i = 0; i < values.length; i++) {
            var id = values[i].id

            if (id > 0 && id <= 10 && ids.indexOf(id) === -1)
                ids.push(id)
        }

        ids.sort(function(left, right) {
            return left - right
        })

        return ids
    }

    function focusWorkspace(id) {
        Quickshell.execDetached([
            "hyprctl",
            "dispatch",
            'hl.dsp.focus({ workspace = "' + id + '" })'
        ])
    }

    implicitWidth: grid.implicitWidth + 1.5
    implicitHeight: grid.implicitHeight

    GridLayout {
        id: grid

        anchors.fill: parent
        anchors.rightMargin: 1.5

        rows: 1
        columnSpacing: theme.workspaceGap

        Repeater {
            model: root.workspaceIds()

            WidgetButton {
                required property int modelData

                readonly property var workspace: root.workspaceById(modelData)

                readonly property bool occupied:
                    workspace !== null &&
                    workspace.toplevels.values.length > 0

                readonly property bool focused:
                    Hyprland.focusedWorkspace !== null &&
                    Hyprland.focusedWorkspace.id === modelData

                text: modelData === 10 ? "0" : String(modelData)

		    foreground: focused
		    ? theme.accent
		    : theme.text

                opacity: occupied || focused
                    ? 1
                    : theme.workspaceEmptyOpacity

                fixedWidth: theme.workspaceWidth
                fixedHeight: theme.barHeight

                active: false

                onPressed: function() {
                    root.focusWorkspace(modelData)
                }
            }
        }
    }
}
