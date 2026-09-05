import QtQuick

Text {
    property string label: ""
    property string value: ""
    color: "#cdd6f4"
    font.pointSize: 10
    text: (label === "" ? "" : label + ": ") +
          (value === "" ? "unavailable" : value)
    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
}
