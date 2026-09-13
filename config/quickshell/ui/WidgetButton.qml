import QtQuick
import "../theme"

Item {
    id: root

    property string text: ""
    property color foreground: theme.text
    property color activeColor: theme.red
    property bool active: false
    property string fontFamily: "monospace"
    property real fontSize: theme.fontBody

    property real horizontalMargin: 8.5
    property real verticalPadding: 6
    property real fixedWidth: -1
    property real fixedHeight: -1

    signal pressed(int button)

    Theme {
        id: theme
    }

    implicitWidth: fixedWidth > 0
        ? fixedWidth
        : Math.max(12, label.implicitWidth + horizontalMargin * 2)

    implicitHeight: fixedHeight > 0
        ? fixedHeight
        : theme.barHeight

    Behavior on opacity {
        NumberAnimation {
            duration: 140
            easing.type: Easing.OutCubic
        }
    }

    Text {
        id: label

        anchors.centerIn: parent

        text: root.text
        color: root.active ? root.activeColor : root.foreground

        font.family: root.fontFamily
        font.pixelSize: root.fontSize
        renderType: Text.NativeRendering

        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    MouseArea {
        anchors.fill: parent

        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor

        onClicked: function(mouse) {
            root.pressed(mouse.button)
        }
    }
}
