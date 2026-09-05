import QtQuick

Rectangle {
    id: root
    property string label: ""
    property bool highlighted: false
    signal clicked()

    width: 120
    height: 28
    radius: 5
    color: highlighted ? "#89b4fa" : "#45475a"
    border.color: "#585b70"
    border.width: 1

    Text {
        anchors.centerIn: parent
        text: root.label
        color: root.highlighted ? "#11111b" : "#cdd6f4"
        font.pointSize: 10
    }
    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
