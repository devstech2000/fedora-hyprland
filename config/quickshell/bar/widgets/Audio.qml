import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../../theme"
import "../../ui"
import "../popups"

WidgetButton {
    id: root

    Theme {
        id: theme
    }
    
    property var popupManager

    readonly property var sink: Pipewire.defaultAudioSink

    readonly property real volume:
        sink && sink.audio ? sink.audio.volume : 0

    readonly property bool muted:
        sink && sink.audio ? sink.audio.muted : false

    function volumeIcon() {
        if (!sink || !sink.audio)
            return ""

        if (muted || volume === 0)
            return ""

        if (volume >= 0.67)
            return ""

        if (volume >= 0.34)
            return ""

        return ""
    }

    text: "\uf025" 
    foreground: theme.accent
    fontFamily: "Cascadia Mono NF"
    fontSize: 20

    fixedWidth: 26
    fixedHeight: theme.barHeight

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    AudioPopup {
        id: audioPopup
        anchorItem: root
    }

    onPressed: function(button) {
        if (!root.sink || !root.sink.audio)
            return

        if (button === Qt.RightButton)
            root.sink.audio.muted = !root.sink.audio.muted
        else if (button === Qt.LeftButton)
            root.popupManager.toggle(audioPopup)
    }
}
