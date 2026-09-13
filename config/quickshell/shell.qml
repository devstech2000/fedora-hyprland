import QtQuick
import Quickshell
import "bar"

ShellRoot {
    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData
            targetScreen: modelData
        }
    }
}
