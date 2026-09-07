import QtQuick
import QtQuick.Controls
import "Theme.js" as Theme

Column {
    property string title: ""
    property string subtitle: ""
    width: parent.width
    spacing: 7
    bottomPadding: 10
    Label {
        text: parent.title
        width: parent.width
        color: Theme.text
        font.pixelSize: 28
        font.weight: Font.DemiBold
        font.letterSpacing: -0.6
        wrapMode: Text.WordWrap
    }
    Label {
        text: parent.subtitle
        width: parent.width
        color: Theme.muted
        font.pixelSize: 13
        wrapMode: Text.WordWrap
        visible: text !== ""
    }
}
