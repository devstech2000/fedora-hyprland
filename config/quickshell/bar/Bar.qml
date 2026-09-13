import QtQuick
import Quickshell
import "../theme"
import "widgets"

PanelWindow {
    required property var targetScreen
    screen: targetScreen

    Theme {
        id: theme
    }

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: theme.barHeight
    exclusiveZone: theme.barHeight
    color: theme.base
	
    QtObject {
	    id: popupManager

	    property var activePopup: null

	    function toggle(popup) {
	        if (activePopup && activePopup !== popup)
	            activePopup.close()

	        if (popup.visible) {
	            popup.close()

	            if (activePopup === popup)
	                activePopup = null
	        } else {
	            popup.open()
	            activePopup = popup
	        }
	    }
     }


    Item {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            Workspaces {}
        }

        Clock {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
	    spacing: 6

	    BluetoothWidget {
		    popupManager: popupManager
	    }
		
	    Audio {
		    popupManager: popupManager
	    }
	    Network {
		    popupManager: popupManager
    	    }
	    Power {
		    popupManager: popupManager
	    }
        }
    }
}
