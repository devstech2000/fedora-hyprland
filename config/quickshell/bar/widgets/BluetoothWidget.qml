import QtQuick
import Quickshell.Bluetooth
import "../../theme"
import "../../ui"
import "../popups"

WidgetButton {
    id: root

    property var popupManager

    Theme {
        id: theme
    }

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devices:
        Bluetooth.devices ? Bluetooth.devices.values : []

    readonly property int connectedCount: {
        var count = 0

        for (var i = 0; i < devices.length; i++) {
            if (devices[i] && devices[i].connected)
                count++
        }

        return count
    }

    visible: adapter !== null

    text: {
        if (!adapter || !adapter.enabled)
            return "󰂲"

        if (connectedCount > 0)
            return "󰂱"

        return "󰂯"
    }

    fontFamily: "Cascadia Mono NF"
    fontSize: 17

    foreground:
        adapter && adapter.enabled
            ? theme.accent
            : theme.subtext0

    fixedWidth: 26
    fixedHeight: theme.barHeight

    BluetoothPopup {
        id: bluetoothPopup
        anchorItem: root
    }

    onPressed: function(button) {
        if (button === Qt.LeftButton)
            root.popupManager.toggle(bluetoothPopup)
    }
}
