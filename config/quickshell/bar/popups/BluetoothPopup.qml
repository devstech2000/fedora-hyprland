import QtQuick
import Quickshell
import Quickshell.Bluetooth
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

    readonly property var adapter: Bluetooth.defaultAdapter

    readonly property var devices:
        Bluetooth.devices ? Bluetooth.devices.values : []

    function deviceLabel(device) {
        if (!device)
            return ""

        return String(
            device.deviceName || device.name || ""
        ).trim()
    }

    function humanName(device) {
        var name = deviceLabel(device)

        if (name === "")
            return false

        if (/^([0-9a-f]{2}:){5}[0-9a-f]{2}$/i.test(name))
            return false

        return true
    }

    function deviceFor(address) {
        for (var i = 0; i < devices.length; i++) {
            var device = devices[i]

            if (device && device.address === address)
                return device
        }

        return null
    }

    function makeRow(device) {
        return {
            address: device.address || "",
            name: deviceLabel(device),

            connected: !!device.connected,
            paired: !!device.paired,
            bonded: !!device.bonded,
            trusted: !!device.trusted,

            pairing: !!device.pairing,
            state: device.state,

            batteryAvailable:
                !!device.batteryAvailable,

            battery:
                device.batteryAvailable
                    ? device.battery
                    : 0
        }
    }

    readonly property var groups: {
        var connected = []
        var paired = []
        var available = []

        for (var i = 0; i < devices.length; i++) {
            var device = devices[i]

            if (!device || !humanName(device))
                continue

            var row = makeRow(device)

            if (device.connected) {
                connected.push(row)
            } else if (
                device.paired
                || device.bonded
                || device.trusted
            ) {
                paired.push(row)
            } else {
                available.push(row)
            }
        }

        function sortRows(list) {
            list.sort(function(a, b) {
                return a.name.localeCompare(b.name)
            })

            return list
        }

        return {
            connected: sortRows(connected),
            paired: sortRows(paired),
            available: sortRows(available)
        }
    }

    function activate(row) {
        var device = deviceFor(row.address)

        if (!device)
            return

        if (device.connected) {
            device.disconnect()
            return
        }

        if (
            device.paired
            || device.bonded
            || device.trusted
        ) {
            device.connect()
            return
        }

        device.pair()
    }

    function forget(row) {
        var device = deviceFor(row.address)

        if (device)
            device.forget()
    }

    function toggleBluetooth() {
        if (!adapter)
            return

        adapter.enabled = !adapter.enabled
    }

    function open() {
        visible = true
    }

    function close() {
        visible = false
    }

    function toggle() {
        visible ? close() : open()
    }

    // Solange das Popup offen ist,
    // nach Geräten suchen.
    Timer {
        interval: 1000
        repeat: true
        triggeredOnStart: true

        running:
            root.visible
            && root.adapter
            && root.adapter.enabled
            && !root.adapter.discovering

        onTriggered: {
            if (root.adapter)
                root.adapter.discovering = true
        }
    }

    // Discovery nach dem Schließen beenden.
    Timer {
        interval: 1000
        repeat: true

        property int attempts: 0

        running:
            !root.visible
            && root.adapter
            && root.adapter.discovering

        onRunningChanged: {
            if (running)
                attempts = 0
        }

        onTriggered: {
            attempts++

            if (!root.adapter) {
                stop()
                return
            }

            root.adapter.discovering = false

            if (attempts >= 3)
                stop()
        }
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
            Item {
                width: parent.width
                height: 44

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    text: {
                        if (
                            !root.adapter
                            || !root.adapter.enabled
                        )
                            return "󰂲"

                        if (
                            root.groups.connected.length > 0
                        )
                            return "󰂱"

                        return "󰂯"
                    }

                    color:
                        root.adapter
                        && root.adapter.enabled
                            ? theme.accent
                            : theme.subtext0

                    font.family: "Cascadia Mono NF"
                    font.pixelSize: 24
                }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 38

                    anchors.verticalCenter:
                        parent.verticalCenter

                    Text {
                        text: "Bluetooth"

                        color: theme.text

                        font.pixelSize: 18
                        font.bold: true
                    }

                    Text {
                        text: {
                            if (!root.adapter)
                                return "Kein Adapter"

                            if (!root.adapter.enabled)
                                return "Ausgeschaltet"

                            if (
                                root.groups.connected.length
                                > 0
                            )
                                return (
                                    root.groups.connected.length
                                    + " verbunden"
                                )

                            return "Bereit"
                        }

                        color: theme.subtext0
                        font.pixelSize: 11
                    }
                }

                // Bluetooth an / aus
                Rectangle {
                    visible: root.adapter !== null

                    anchors.right: parent.right

                    anchors.verticalCenter:
                        parent.verticalCenter

                    width: 42
                    height: 22
                    radius: 11

                    color:
                        root.adapter
                        && root.adapter.enabled
                            ? theme.accent
                            : theme.surface0

                    Rectangle {
                        width: 16
                        height: 16
                        radius: 8

                        anchors.verticalCenter:
                            parent.verticalCenter

                        x:
                            root.adapter
                            && root.adapter.enabled
                                ? parent.width
                                    - width
                                    - 3
                                : 3

                        color: theme.text
                    }

                    MouseArea {
                        anchors.fill: parent

                        cursorShape:
                            Qt.PointingHandCursor

                        onClicked:
                            root.toggleBluetooth()
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1

                color: theme.surface1
            }

            Flickable {
                width: parent.width

                height: Math.min(
                    deviceContent.implicitHeight,
                    260
                )

                clip: true

                contentWidth: width
                contentHeight:
                    deviceContent.implicitHeight

                boundsBehavior:
                    Flickable.StopAtBounds

                interactive:
                    contentHeight > height

                Column {
                    id: deviceContent

                    width: parent.width
                    spacing: 10

                    DeviceSection {
                        title: "CONNECTED"

                        rows:
                            root.groups.connected
                    }

                    DeviceSection {
                        title: "PAIRED"

                        rows:
                            root.groups.paired
                    }

                    DeviceSection {
                        title: "AVAILABLE"

                        visible:
                            root.adapter
                            && root.adapter.enabled

                        rows:
                            root.groups.available
                    }

                    Text {
                        visible:
                            root.adapter
                            && root.adapter.enabled
                            && root.groups.connected.length === 0
                            && root.groups.paired.length === 0
                            && root.groups.available.length === 0

                        text:
                            root.adapter.discovering
                                ? "Suche nach Geräten…"
                                : "Keine Geräte gefunden"

                        color: theme.subtext0

                        font.pixelSize:
                            theme.fontBody

                        topPadding: 8
                    }

                    Text {
                        visible:
                            root.adapter
                            && !root.adapter.enabled

                        text:
                            "Bluetooth ist ausgeschaltet"

                        color: theme.subtext0

                        font.pixelSize:
                            theme.fontBody

                        topPadding: 8
                    }
                }
            }
        }
    }

    component DeviceSection: Column {
        property string title: ""
        property var rows: []

        width: parent.width
        spacing: 4

        visible: rows.length > 0

        Text {
            text: parent.title

            color: theme.subtext0

            font.pixelSize: 10
            font.bold: true

            bottomPadding: 4
        }

        Repeater {
            model: parent.rows

            delegate: DeviceRow {
                required property var modelData

                width: parent.width
                row: modelData
            }
        }
    }

    component DeviceRow: Rectangle {
        property var row

        height: 46
        radius: theme.radius

        color:
            row.connected
                ? theme.surface0
                : "transparent"

        Text {
            id: deviceIcon

            anchors.left: parent.left
            anchors.leftMargin: 10

            anchors.verticalCenter:
                parent.verticalCenter

            text:
                row.connected
                    ? "󰂱"
                    : "󰂯"

            color:
                row.connected
                    ? theme.accent
                    : theme.text

            font.family: "Cascadia Mono NF"
            font.pixelSize: 18
        }

        Column {
            anchors.left: deviceIcon.right
            anchors.leftMargin: 10

            anchors.right: forgetButton.left
            anchors.rightMargin: 8

            anchors.verticalCenter:
                parent.verticalCenter

            Text {
                width: parent.width

                text:
                    row.name
                    || "Bluetooth-Gerät"

                color:
                    row.connected
                        ? theme.accent
                        : theme.text

                font.pixelSize:
                    theme.fontBody

                font.bold:
                    row.connected

                elide:
                    Text.ElideRight
            }

            Text {
                visible:
                    row.connected
                    || row.pairing
                    || row.state
                        === BluetoothDeviceState.Connecting
                    || row.state
                        === BluetoothDeviceState.Disconnecting

                text: {
                    if (row.pairing)
                        return "Pairing…"

                    if (
                        row.state
                        === BluetoothDeviceState.Connecting
                    )
                        return "Verbinde…"

                    if (
                        row.state
                        === BluetoothDeviceState.Disconnecting
                    )
                        return "Trenne…"

                    if (
                        row.connected
                        && row.batteryAvailable
                    )
                        return (
                            Math.round(
                                row.battery * 100
                            )
                            + "%"
                        )

                    if (row.connected)
                        return "Verbunden"

                    return ""
                }

                color: theme.subtext0

                font.pixelSize: 10
            }
        }

        Rectangle {
            id: forgetButton

            visible:
                row.paired
                || row.bonded
                || row.trusted
                || row.connected

            anchors.right: parent.right
            anchors.rightMargin: 8

            anchors.verticalCenter:
                parent.verticalCenter

            width: 26
            height: 26

            radius: theme.radius
            color: "transparent"

            Text {
                anchors.centerIn: parent

                text: "\uf00d"
                color: theme.subtext0

                font.family:
                    "Cascadia Mono NF"

                font.pixelSize: 12
            }

            MouseArea {
                anchors.fill: parent

                cursorShape:
                    Qt.PointingHandCursor

                onClicked:
                    root.forget(row)
            }
        }

        MouseArea {
            anchors.left: parent.left
            anchors.right: forgetButton.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            cursorShape:
                Qt.PointingHandCursor

            onClicked:
                root.activate(row)
        }
    }
}
