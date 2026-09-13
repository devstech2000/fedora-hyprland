import QtQuick
import "../../theme"
import "../../ui"
import "../popups"

WidgetButton {
    id: root
    
    property var popupManager
    
    Theme {
        id: theme
    }
    

    text: "\uf011"
    fontFamily: "Cascadia Mono NF"
    fontSize: 18
    foreground: theme.accent

    fixedWidth: 26
    fixedHeight: theme.barHeight

    PowerPopup {
        id: powerPopup
        anchorItem: root
    }

    onPressed: function(button) {
        if (button === Qt.LeftButton)
            root.popupManager.toggle(powerPopup)
    }
}
