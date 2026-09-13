import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
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

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var nodes: Pipewire.nodes
        ? Pipewire.nodes.values
        : []

    readonly property var sinks: {
        var list = []

        for (var i = 0; i < nodes.length; i++) {
            var node = nodes[i]

            if (node && node.isSink && !node.isStream)
                list.push(node)
        }

        return list
    }

    readonly property real volume:
        sink && sink.audio
            ? sink.audio.volume
            : 0

    readonly property bool muted:
        sink && sink.audio
            ? sink.audio.muted
            : false

    PwObjectTracker {
        objects: root.sinks
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

    function setVolume(value) {
        if (!sink || !sink.audio)
            return

        sink.audio.volume =
            Math.max(0, Math.min(1, value))
    }

    function toggleMute() {
        if (sink && sink.audio)
            sink.audio.muted = !sink.audio.muted
    }

    function setDefaultSink(node) {
        if (!node)
            return

        Pipewire.preferredDefaultAudioSink = node
    }

    function deviceName(node) {
        if (!node)
            return "Unbekannt"

        if (node.nickname)
            return node.nickname

        if (node.description)
            return node.description

        return node.name || "Unbekannt"
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

            // Header
            Row {
                width: parent.width
                spacing: 10

                Text {
                    text: root.muted ? "" : ""
                    color: theme.text
                    font.family: "monospace"
                    font.pixelSize: 22

                    anchors.verticalCenter:
                        parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            root.toggleMute()
                        }
                    }
                }

                Text {
                    text: "Audio"
                    color: theme.text
                    font.pixelSize: 18
                    font.bold: true

                    anchors.verticalCenter:
                        parent.verticalCenter
                }
            }

            // Lautstärke
            Item {
                width: parent.width
                height: 24

                Text {
                    id: volumePercent

                    anchors.right: parent.right
                    anchors.verticalCenter:
                        parent.verticalCenter

                    text:
                        Math.round(root.volume * 100) + "%"

                    color: theme.subtext0
                    font.pixelSize: theme.fontBody
                }

                Rectangle {
                    id: volumeTrack

                    anchors.left: parent.left
                    anchors.right: volumePercent.left
                    anchors.rightMargin: 14
                    anchors.verticalCenter:
                        parent.verticalCenter

                    height: 6
                    radius: 3
                    color: theme.surface0

                    // Gefüllter Bereich
                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter:
                            parent.verticalCenter

                        width:
                            parent.width
                            * Math.max(
                                0,
                                Math.min(1, root.volume)
                            )

                        height: parent.height
                        radius: parent.radius
                        color: theme.accent
                    }

                    // Knopf
                    Rectangle {
                        width: 14
                        height: 14
                        radius: 7

                        color: theme.text

                        anchors.verticalCenter:
                            parent.verticalCenter

                        x: Math.max(
                            -width / 2,
                            Math.min(
                                volumeTrack.width - width / 2,
                                volumeTrack.width
                                    * Math.max(
                                        0,
                                        Math.min(
                                            1,
                                            root.volume
                                        )
                                    )
                                    - width / 2
                            )
                        )
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.topMargin: -8
                        anchors.bottomMargin: -8

                        cursorShape:
                            Qt.PointingHandCursor

                        function updateVolume(mouseX) {
                            root.setVolume(
                                mouseX
                                / volumeTrack.width
                            )
                        }

                        onPressed: function(mouse) {
                            updateVolume(mouse.x)
                        }

                        onPositionChanged:
                            function(mouse) {
                                if (pressed)
                                    updateVolume(mouse.x)
                            }
                    }
                }
            }

            // Trennlinie
            Rectangle {
                width: parent.width
                height: 1
                color: theme.surface1
            }

            Text {
                text: "AUSGABE"
                color: theme.subtext0
                font.pixelSize: 10
                font.bold: true
            }

            // Ausgabegeräte
            Repeater {
                model: root.sinks

                delegate: Rectangle {
                    required property var modelData

                    width: content.width
                    height: 38
                    radius: theme.radius

                    readonly property bool active:
                        root.sink
                        && modelData
                        && root.sink.id === modelData.id

                    color:
                        active
                            ? theme.surface0
                            : "transparent"

                    Row {
                        anchors {
                            fill: parent
                            leftMargin: 10
                            rightMargin: 10
                        }

                        spacing: 10

                        Text {
                            text: "󰓃"

                            color:
                                active
                                    ? theme.accent
                                    : theme.text

                            font.family: "monospace"
                            font.pixelSize: 16

                            anchors.verticalCenter:
                                parent.verticalCenter
                        }

                        Text {
                            text:
                                root.deviceName(modelData)

                            color:
                                active
                                    ? theme.accent
                                    : theme.text

                            font.pixelSize:
                                theme.fontBody

                            font.bold: active
                            elide: Text.ElideRight

                            width:
                                parent.width - 40

                            anchors.verticalCenter:
                                parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            root.setDefaultSink(
                                modelData
                            )
                        }
                    }
                }
            }
        }
    }
}
