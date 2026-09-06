import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: page
    clip: true
    contentWidth: availableWidth

    property int selectedScene: -1

    Column {
        width: page.availableWidth
        spacing: 14
        padding: 24

        Label {
            text: "Scenes"
            font.pixelSize: 22
            font.bold: true
            color: "#E8DCCB"
        }

        Rectangle {
            width: parent.width
            Layout.preferredHeight: Math.min(280, 48 * Math.max(center.sceneNames.length, 1))
            radius: 10
            color: "#292420"
            border.color: "#3A332B"
            border.width: 1
            clip: true

            ListView {
                id: sceneList
                anchors.fill: parent
                anchors.margins: 6
                model: center.sceneNames
                currentIndex: page.selectedScene
                onCurrentIndexChanged: page.selectedScene = currentIndex
                delegate: ItemDelegate {
                    required property string modelData
                    required property int index
                    width: sceneList.width - 12
                    height: 40
                    highlighted: ListView.isCurrentItem
                    text: modelData
                    onClicked: sceneList.currentIndex = index
                    contentItem: Label {
                        text: parent.text
                        color: parent.highlighted ? "#E2A35B" : "#E8DCCB"
                        font.pixelSize: 13
                        font.bold: parent.highlighted
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 10
                    }
                    background: Rectangle {
                        radius: 6
                        color: parent.highlighted ? "#3A332B" : "transparent"
                    }
                }
                Label {
                    anchors.centerIn: parent
                    visible: sceneList.count === 0
                    text: "No scenes yet — create ~/.config/msi-linux-center/scenes.json\n"
                          + "and press Reload. See docs/phase8-scenes-design.md."
                    color: "#8C7F6F"
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        Row {
            spacing: 10
            Button {
                text: "Apply selected scene"
                enabled: page.selectedScene >= 0 && !center.sceneApplying
                onClicked: center.applyScene(center.sceneNames[page.selectedScene])
            }
            Button {
                text: "Reload"
                onClicked: center.reloadScenes()
            }
            BusyIndicator {
                visible: center.sceneApplying
                implicitWidth: 24
                implicitHeight: 24
            }
        }

        Rectangle {
            visible: center.sceneResultText !== ""
            width: parent.width
            radius: 10
            color: "#2C3220"
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 4
                Repeater {
                    model: center.sceneResultText.split("\n")
                    Label {
                        required property string modelData
                        text: modelData
                        color: modelData.startsWith("FAIL") ? "#DD6B58" : "#A9BA7C"
                        font.pixelSize: 12
                        font.family: "monospace"
                    }
                }
            }
            implicitHeight: Math.max(40, 22 * center.sceneResultText.split("\n").length + 20)
        }

        Label {
            text: "Scenes apply the same daemon-gated writes as the individual controls; "
                  + "settings whose opt-in is off are reported and skipped. RGB is never "
                  + "persisted by a scene."
            color: "#8C7F6F"
            font.pixelSize: 11
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            width: parent.width
        }
    }
}
