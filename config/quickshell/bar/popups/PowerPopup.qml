import QtQuick
import Quickshell
import Quickshell.Io
import "../../theme"

PopupWindow {
    id: root

    property var anchorItem

    Theme {
        id: theme
    }

    visible: false
    color: "transparent"

    implicitWidth: 360
    implicitHeight: content.implicitHeight + 32

    anchor {
        item: root.anchorItem
        rect.x: root.anchorItem
            ? root.anchorItem.width - root.implicitWidth
            : 0
        rect.y: root.anchorItem
            ? root.anchorItem.height
            : 0
    }

    function open() {
        visible = true
    }

    function close() {
        visible = false
    }

    function toggle() {
        visible = !visible
    }

    Rectangle {
        anchors.fill: parent

        color: theme.base
        radius: theme.radius

        border.width: theme.borderWidth
        border.color: theme.accent

        Column {
            id: content

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 16
            }

            spacing: 14

            Text {
                text: "Power"
                color: theme.text
                font.pixelSize: 18
                font.bold: true
            }

            Rectangle {
                width: parent.width
                height: 1
                color: theme.surface1
            }

            Text {
                text: "SYSTEM"
                color: theme.subtext0
                font.pixelSize: 10
                font.bold: true
            }

            Row {
                width: parent.width
                spacing: 8

                PowerButton {
                    text: "Lock"
                    icon: "\uf023"
                    command: ["hyprlock"]
                }

                PowerButton {
                    text: "Suspend"
                    icon: "\uf186"
                    command: ["systemctl", "suspend"]
                }
            }

            Row {
                width: parent.width
                spacing: 8

                PowerButton {
                    text: "Logout"
                    icon: "\uf08b"
                    command: ["hyprctl", "dispatch", "exit"]
                }

                PowerButton {
                    text: "Reboot"
                    icon: "\uf021"
                    command: ["systemctl", "reboot"]
                }
            }

            PowerButton {
                width: parent.width
                text: "Shutdown"
                icon: "\uf011"
                command: ["systemctl", "poweroff"]
            }
        }
    }

    component PowerButton: Rectangle {
        property string text: ""
        property string icon: ""
        property var command: []

        width: (content.width - 8) / 2
        height: 48

        radius: theme.radius
        color: theme.surface0

        Row {
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: parent.parent.icon
                color: theme.accent
                font.family: "Cascadia Mono NF"
                font.pixelSize: 16
            }

            Text {
                text: parent.parent.text
                color: theme.text
                font.pixelSize: theme.fontBody
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                root.close()
                Quickshell.execDetached(parent.command)
            }
        }
    }
}
