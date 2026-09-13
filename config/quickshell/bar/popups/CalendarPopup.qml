import QtQuick
import Quickshell
import "../../theme"

PopupWindow {
    id: root

    property var anchorItem: null

    property date today: new Date()
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()

    readonly property date viewDate:
        new Date(viewYear, viewMonth, 1)

    readonly property bool viewingCurrentMonth:
        viewYear === today.getFullYear()
        && viewMonth === today.getMonth()

    Theme {
        id: theme
    }

    anchor.item: root.anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom

    width: 560
    height: content.implicitHeight + 40

    visible: false
    grabFocus: true
    color: "transparent"

    function open() {
        today = new Date()
        viewYear = today.getFullYear()
        viewMonth = today.getMonth()
        visible = true
    }

    function close() {
        visible = false
    }

    function toggle() {
        if (visible)
            close()
        else
            open()
    }

    function moveMonth(delta) {
        var next = new Date(viewYear, viewMonth + delta, 1)
        viewYear = next.getFullYear()
        viewMonth = next.getMonth()
    }

    function goToToday() {
        viewYear = today.getFullYear()
        viewMonth = today.getMonth()
    }

    function pad2(value) {
        return value < 10 ? "0" + value : String(value)
    }

    function dateKey(date) {
        return date.getFullYear()
            + "-" + pad2(date.getMonth() + 1)
            + "-" + pad2(date.getDate())
    }

    function isoWeek(date) {
        var d = new Date(Date.UTC(
            date.getFullYear(),
            date.getMonth(),
            date.getDate()
        ))

        var day = d.getUTCDay() || 7
        d.setUTCDate(d.getUTCDate() + 4 - day)

        var yearStart =
            new Date(Date.UTC(d.getUTCFullYear(), 0, 1))

        return Math.ceil(
            (((d - yearStart) / 86400000) + 1) / 7
        )
    }

    function yearProgress() {
        var start = new Date(today.getFullYear(), 0, 1)
        var end = new Date(today.getFullYear() + 1, 0, 1)

        return Math.max(
            0,
            Math.min(
                1,
                (today - start) / (end - start)
            )
        )
    }

    function monthWeeks() {
        var weeks = []

        // Montag als erster Wochentag
        var first = new Date(viewYear, viewMonth, 1)
        var weekday = first.getDay()
        var offset = (weekday + 6) % 7

        var cursor =
            new Date(viewYear, viewMonth, 1 - offset)

        for (var w = 0; w < 6; w++) {
            var days = []

            for (var d = 0; d < 7; d++) {
                var current = new Date(cursor)

                days.push({
                    day: current.getDate(),
                    month: current.getMonth(),
                    year: current.getFullYear(),
                    inMonth:
                        current.getMonth() === viewMonth
                        && current.getFullYear() === viewYear,
                    today:
                        dateKey(current) === dateKey(today),
                    weekend:
                        current.getDay() === 0
                        || current.getDay() === 6
                })

                cursor.setDate(cursor.getDate() + 1)
            }

            var thursday =
                new Date(
                    days[0].year,
                    days[0].month,
                    days[0].day + 3
                )

            weeks.push({
                week: isoWeek(thursday),
                days: days
            })
        }

        return weeks
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes

        onDateChanged: {
            if (root.dateKey(date) !== root.dateKey(root.today))
                root.today = date
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
	    
            anchors.fill: parent
            anchors.margins: 20

            spacing: 12

            // Großes heutiges Datum
            Text {
                anchors.horizontalCenter: parent.horizontalCenter

                text: Qt.formatDate(root.today, "MMMM d")

                color: theme.text
                font.family: "monospace"
                font.pixelSize: 52
                font.bold: true
                renderType: Text.NativeRendering

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked: root.goToToday()
                }
            }

            // Jahresfortschritt
            Item {
                width: 424
                height: 20
                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    id: yearLabel

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    text: root.today.getFullYear()
                    color: theme.subtext0
                    font.family: "monospace"
                    font.pixelSize: 11
                }

                Text {
                    id: percentLabel

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    text: Math.round(root.yearProgress() * 100) + "%"
                    color: theme.text
                    font.family: "monospace"
                    font.pixelSize: 11
                }

                Rectangle {
                    anchors.left: yearLabel.right
                    anchors.right: percentLabel.left
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter

                    height: 6
                    radius: 3

                    color: theme.surface0

                    Rectangle {
                        width: parent.width * root.yearProgress()
                        height: parent.height
                        radius: parent.radius

                        color: theme.accent
                    }
                }
            }

            Item {
                width: 424
                height: 270
                anchors.horizontalCenter: parent.horizontalCenter

                Column {
                    anchors.fill: parent
                    spacing: 3

                    // Wochentage
                    Row {
                        spacing: 2

                        Text {
                            width: 32
                            height: 16
                            text: "W"

                            color: theme.subtext0
                            font.family: "monospace"
                            font.pixelSize: 10
                            font.bold: true

                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        Item {
                            width: 14
                            height: 16
                        }

                        Repeater {
                            model: ["MO", "DI", "MI", "DO", "FR", "SA", "SO"]

                            Text {
                                required property string modelData

                                width: 52
                                height: 16

                                text: modelData

                                color: theme.subtext0
                                font.family: "monospace"
                                font.pixelSize: 10
                                font.bold: true

                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    // Sechs Kalenderwochen
                    Repeater {
                        model: root.monthWeeks()

                        Row {
                            required property var modelData
                            spacing: 2

                            Text {
                                width: 32
                                height: 34

                                text: modelData.week
                                color: theme.subtext0

                                font.family: "monospace"
                                font.pixelSize: 10

                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            Item {
                                width: 14
                                height: 34
                            }

                            Repeater {
                                model: modelData.days

                                Rectangle {
                                    required property var modelData

                                    width: 52
                                    height: 34

                                    radius: theme.radius
                                    color: "transparent"

                                    border.width:
                                        modelData.today
                                        ? theme.borderWidth
                                        : 0

                                    border.color: theme.accent

                                    Text {
                                        anchors.centerIn: parent

                                        text: modelData.day

                                        color:
                                            !modelData.inMonth
                                            ? theme.surface1
                                            : modelData.weekend
                                                ? theme.subtext0
                                                : theme.text

                                        font.family: "monospace"
                                        font.pixelSize: theme.fontBody
                                        font.bold: modelData.today
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Monatsnavigation
            Item {
                width: 424
                height: 30
                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    anchors.centerIn: parent

                    width: 180

                    text:
                        Qt.formatDate(
                            root.viewDate,
                            "MMMM yyyy"
                        ).toUpperCase()

                    color: theme.subtext0

                    font.family: "monospace"
                    font.pixelSize: theme.fontBody
                    font.letterSpacing: 1

                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    text: "‹"
                    color: theme.text
                    font.pixelSize: 22

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -10
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.moveMonth(-1)
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    text: "›"
                    color: theme.text
                    font.pixelSize: 22

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -10
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.moveMonth(1)
                    }
                }
            }
        }
    }
}
