import QtQuick

// Toast-style on-screen notification (GhostDeck-like OSD) shown bottom-
// right for a few seconds whenever a write action completes. Frameless,
// always on top, never takes focus; click to dismiss.
Window {
    id: osd
    visible: false
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
           | Qt.WindowDoesNotAcceptFocus
    width: 380
    height: 92
    color: "transparent"

    property string titleText: ""
    property string bodyText: ""
    property bool errorState: false

    function showMessage(title, body, isError) {
        titleText = title
        bodyText = body
        errorState = isError
        x = Math.max(8, Screen.desktopAvailableWidth - width - 24)
        y = Math.max(8, Screen.desktopAvailableHeight - height - 56)
        show()
        raise()
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: 3200
        onTriggered: osd.hide()
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: osd.errorState ? "#3A2622" : "#2A241E"
        border.color: osd.errorState ? "#DD6B58" : "#4A4237"
        border.width: 1
        opacity: 0.97

        Column {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 12
            anchors.topMargin: 12
            anchors.bottomMargin: 10
            spacing: 4

            Row {
                width: parent.width
                spacing: 8
                Rectangle {
                    width: 10
                    height: 10
                    radius: 5
                    anchors.verticalCenter: parent.verticalCenter
                    color: osd.errorState ? "#DD6B58" : "#A9BA7C"
                }
                Text {
                    text: osd.titleText
                    color: "#E8DCCB"
                    font.pixelSize: 14
                    font.bold: true
                    width: parent.width - 18
                    elide: Text.ElideRight
                }
            }
            Text {
                text: osd.bodyText
                color: "#B5A896"
                font.pixelSize: 12
                width: parent.width
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: osd.hide()
        }
    }
}
