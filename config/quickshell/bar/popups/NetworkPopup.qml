import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Networking
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

    readonly property var devices:
        Networking.devices ? Networking.devices.values : []

    function findDevice(type) {
        var fallback = null

        for (var i = 0; i < devices.length; i++) {
            var device = devices[i]

            if (!device || device.type !== type)
                continue

            if (device.connected)
                return device

            if (!fallback)
                fallback = device
        }

        return fallback
    }

    readonly property var wifiDevice:
        findDevice(DeviceType.Wifi)

    readonly property var wiredDevice:
        findDevice(DeviceType.Wired)

    readonly property var networkObjects:
        wifiDevice && wifiDevice.networks
            ? wifiDevice.networks.values
            : []

    property var networks: []

    property string passwordSsid: ""
    property string passwordText: ""

    function connectedWifi() {
        for (var i = 0; i < networkObjects.length; i++) {
            var network = networkObjects[i]

            if (network && network.connected)
                return network
        }

        return null
    }

    function currentName() {
        if (wiredDevice && wiredDevice.connected)
            return "Ethernet"

        var wifi = connectedWifi()

        if (wifi)
            return wifi.name || "Wi-Fi"

        return "Nicht verbunden"
    }

    function networkForSsid(ssid) {
        for (var i = 0; i < networkObjects.length; i++) {
            var network = networkObjects[i]

            if (network && network.name === ssid)
                return network
        }

        return null
    }

    function syncNetworks() {
        var list = []

        for (var i = 0; i < networkObjects.length; i++) {
            var network = networkObjects[i]

            if (!network)
                continue

            list.push({
                ssid: network.name || "",
                connected: !!network.connected,
                known: !!network.known,
                signal: Math.round(
                    (network.signalStrength || 0) * 100
                ),
                security: network.security
            })
        }

        list.sort(function(a, b) {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1

            if (a.known !== b.known)
                return a.known ? -1 : 1

            return b.signal - a.signal
        })

        networks = list
    }

    function requiresPassword(network) {
        return network.security !== WifiSecurityType.Open
            && network.security !== WifiSecurityType.Owe
    }

    function wifiIcon(strength) {
        if (strength >= 75)
            return "󰤨"

        if (strength >= 50)
            return "󰤥"

        if (strength >= 25)
            return "󰤢"

        return "󰤟"
    }

    function activateNetwork(net) {
        var network = networkForSsid(net.ssid)

        if (!network)
            return

        if (network.connected) {
            network.disconnect()
            return
        }

        if (network.known || !requiresPassword(network)) {
            network.connect()
            return
        }

        passwordText = ""
        passwordSsid = net.ssid
    }

    function submitPassword(ssid) {
        var network = networkForSsid(ssid)

        if (!network || passwordText.length === 0)
            return

        network.connectWithPsk(passwordText)

        passwordText = ""
        passwordSsid = ""
    }

    function open() {
        visible = true
    }

    function close() {
        visible = false
        passwordSsid = ""
        passwordText = ""
    }

    function toggle() {
        if (visible)
            close()
        else
            open()
    }

    onNetworkObjectsChanged:
        syncNetworks()

    onVisibleChanged: {
        if (wifiDevice)
            wifiDevice.scannerEnabled = visible

        if (visible)
            syncNetworks()
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
                height: 42

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    text: "\uf1eb"
                    color: theme.accent

                    font.family: "Cascadia Mono NF"
                    font.pixelSize: 22
                }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 34
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: "Network"
                        color: theme.text
                        font.pixelSize: 18
                        font.bold: true
                    }

                    Text {
                        text: root.currentName()
                        color: theme.subtext0
                        font.pixelSize: 11
                    }
                }

                Rectangle {
                    visible: root.wifiDevice !== null

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    width: 42
                    height: 22
                    radius: 11

                    color: Networking.wifiEnabled
                        ? theme.accent
                        : theme.surface0

                    Rectangle {
                        width: 16
                        height: 16
                        radius: 8

                        anchors.verticalCenter: parent.verticalCenter

                        x: Networking.wifiEnabled
                            ? parent.width - width - 3
                            : 3

                        color: theme.text
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            Networking.wifiEnabled =
                                !Networking.wifiEnabled
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: theme.surface1
            }

            Text {
                text: "WI-FI"
                color: theme.subtext0
                font.pixelSize: 10
                font.bold: true
            }

            Flickable {
                width: parent.width
                height: Math.min(
                    networkColumn.implicitHeight,
                    260
                )

                clip: true

                contentWidth: width
                contentHeight: networkColumn.implicitHeight

                boundsBehavior: Flickable.StopAtBounds

                interactive:
                    contentHeight > height

                Column {
                    id: networkColumn

                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: root.networks

                        delegate: Rectangle {
                            required property var modelData

                            width: networkColumn.width

                            height:
                                passwordPanel.visible
                                    ? 88
                                    : 44

                            radius: theme.radius

                            color:
                                modelData.connected
                                    ? theme.surface0
                                    : "transparent"

                            Row {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top

                                    leftMargin: 10
                                    rightMargin: 10
                                }

                                height: 44
                                spacing: 10

                                Text {
                                    text:
                                        root.wifiIcon(
                                            modelData.signal
                                        )

                                    color:
                                        modelData.connected
                                            ? theme.accent
                                            : theme.text

                                    font.family:
                                        "Cascadia Mono NF"

                                    font.pixelSize: 17

                                    anchors.verticalCenter:
                                        parent.verticalCenter
                                }

                                Text {
                                    text:
                                        modelData.ssid !== ""
                                            ? modelData.ssid
                                            : "Hidden"

                                    color:
                                        modelData.connected
                                            ? theme.accent
                                            : theme.text

                                    font.pixelSize:
                                        theme.fontBody

                                    font.bold:
                                        modelData.connected

                                    elide: Text.ElideRight

                                    width:
                                        parent.width - 72

                                    anchors.verticalCenter:
                                        parent.verticalCenter
                                }

                                Text {
                                    visible:
                                        root.requiresPassword(
                                            modelData
                                        )

                                    text: "\uf023"

                                    color: theme.subtext0

                                    font.family:
                                        "Cascadia Mono NF"

                                    font.pixelSize: 12

                                    anchors.verticalCenter:
                                        parent.verticalCenter
                                }
                            }

                            MouseArea {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                }

                                height: 44

                                cursorShape:
                                    Qt.PointingHandCursor

                                onClicked: {
                                    root.activateNetwork(
                                        modelData
                                    )
                                }
                            }

                            Item {
                                id: passwordPanel

                                visible:
                                    root.passwordSsid
                                        === modelData.ssid

                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                    topMargin: 44
                                    leftMargin: 10
                                    rightMargin: 10
                                }

                                height: visible ? 40 : 0

                                TextField {
                                    id: passwordField

                                    anchors.left: parent.left
                                    anchors.right: connectButton.left
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    height: 32

                                    echoMode:
                                        TextInput.Password

                                    placeholderText:
                                        "Passwort"

                                    color: theme.text

                                    text:
                                        root.passwordSsid
                                            === modelData.ssid
                                                ? root.passwordText
                                                : ""

                                    onTextChanged: {
                                        if (
                                            root.passwordSsid
                                            === modelData.ssid
                                        )
                                            root.passwordText =
                                                text
                                    }

                                    onAccepted: {
                                        root.submitPassword(
                                            modelData.ssid
                                        )
                                    }

                                    background: Rectangle {
                                        color: theme.surface0
                                        radius: theme.radius

                                        border.width: 1
                                        border.color:
                                            theme.surface1
                                    }
                                }

                                Rectangle {
                                    id: connectButton

                                    anchors.right: parent.right
                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    width: 34
                                    height: 32

                                    radius: theme.radius
                                    color: theme.accent

                                    Text {
                                        anchors.centerIn: parent

                                        text: "✓"
                                        color: theme.base
                                        font.bold: true
                                    }

                                    MouseArea {
                                        anchors.fill: parent

                                        cursorShape:
                                            Qt.PointingHandCursor

                                        onClicked: {
                                            root.submitPassword(
                                                modelData.ssid
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        visible:
                            Networking.wifiEnabled
                            && root.networks.length === 0

                        text: "Keine Netzwerke gefunden"

                        color: theme.subtext0
                        font.pixelSize: theme.fontBody

                        topPadding: 10
                    }

                    Text {
                        visible:
                            !Networking.wifiEnabled

                        text: "Wi-Fi ist ausgeschaltet"

                        color: theme.subtext0
                        font.pixelSize: theme.fontBody

                        topPadding: 10
                    }
                }
            }
        }
    }
}
