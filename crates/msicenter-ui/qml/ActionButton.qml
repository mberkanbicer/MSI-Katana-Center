import QtQuick
import QtQuick.Controls
import "Theme.js" as Theme

Button {
    id: control
    property bool primary: false
    property bool destructive: false
    hoverEnabled: true
    implicitHeight: 40
    implicitWidth: Math.max(40, contentItem.implicitWidth + leftPadding + rightPadding)
    leftPadding: 16
    rightPadding: 16
    topInset: 0
    bottomInset: 0
    font.pixelSize: 13
    font.weight: Font.Medium
    opacity: enabled ? 1 : 0.45
    contentItem: Label {
        text: control.text
        font: control.font
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        color: control.primary ? Theme.background
                               : control.destructive ? Theme.danger
                                                     : control.checked ? Theme.accent : Theme.text
    }
    background: Rectangle {
        radius: 9
        color: control.down ? Theme.border
                            : control.primary ? Theme.accent
                                              : control.checked ? Theme.accentSoft
                                                                : control.hovered ? Theme.elevated : Theme.surface
        border.color: control.visualFocus || control.checked ? Theme.accent : Theme.border
        border.width: control.visualFocus ? 2 : 1
        Behavior on color { ColorAnimation { duration: 120 } }
    }
}
