import QtQuick
import Quickshell
import "../../theme"
import "../../ui"
import "../popups"

WidgetButton {
    id: root

    Theme {
        id: theme
    }

    property date displayDate: clock.date

    text: Qt.formatDateTime(displayDate, "dddd HH:mm")

    horizontalMargin: 8.75
    verticalPadding: 8.75
    foreground: theme.text

    SystemClock {
        id: clock
        precision: SystemClock.Minutes

        onDateChanged: {
            root.displayDate = date
        }
    }

    CalendarPopup {
        id: calendarPopup
        anchorItem: root
    }

    onPressed: function(button) {
        if (button === Qt.LeftButton)
            calendarPopup.toggle()
    }
}
