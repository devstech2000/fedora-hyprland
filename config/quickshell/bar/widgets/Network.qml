import QtQuick
import Quickshell.Networking
import "../../theme"
import "../../ui"
import "../popups"

WidgetButton {
    id: root

    Theme {
        id: theme
    }
    property var popupManager

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

    readonly property var wifiNetworks:
        wifiDevice && wifiDevice.networks
            ? wifiDevice.networks.values
            : []

    readonly property var connectedWifi: {
        for (var i = 0; i < wifiNetworks.length; i++) {
            if (wifiNetworks[i] && wifiNetworks[i].connected)
                return wifiNetworks[i]
        }

        return null
    }

    text: "\uf1eb"
    fontFamily: "Cascadia Mono NF"
    fontSize: 24

    foreground:
        (wiredDevice && wiredDevice.connected) || connectedWifi
            ? theme.accent
            : theme.subtext0

    fixedWidth: 26
    fixedHeight: theme.barHeight

    NetworkPopup {
        id: networkPopup
        anchorItem: root
    }

    onPressed: function(button) {
        if (button === Qt.LeftButton)
            root.popupManager.toggle(networkPopup)
    }
}
