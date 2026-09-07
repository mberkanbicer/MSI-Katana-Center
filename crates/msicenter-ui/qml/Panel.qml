import QtQuick
import "Theme.js" as Theme

Rectangle {
    radius: 16
    color: Theme.surface
    border.color: Theme.border
    implicitHeight: children.length ? children[0].implicitHeight + 40 : 80
}
