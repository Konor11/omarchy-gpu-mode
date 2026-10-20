import QtQuick
import QtQuick.Controls

Rectangle {
  id: row
  property bool isModeRow: true
  property string mode: ""
  property string title: ""
  property string subtitle: ""
  property bool checked: false
  property string glyph: ""
  property color accent: "#4ade80"
  property color foreground: "#ffffff"
  property string fontFamily: ""
  property var styles: ({})

  signal activate()

  function sp() { return (styles && styles.space) || 8 }
  function pxBody() { return (styles && styles.body) || 12 }

  radius: 8
  color: checked ? Qt.rgba(accent.r, accent.g, accent.b, 0.13) : Qt.rgba(1, 1, 1, 0.04)
  border.color: checked ? accent : Qt.rgba(1, 1, 1, 0.08)
  border.width: checked ? 2 : 1

  Text {
    id: icon
    anchors.left: parent.left
    anchors.leftMargin: sp()
    anchors.verticalCenter: parent.verticalCenter
    text: row.glyph
    color: row.accent
    font.family: row.fontFamily
    font.pixelSize: pxBody() + 2
  }
  Text {
    anchors.left: icon.right
    anchors.leftMargin: sp()
    anchors.verticalCenter: parent.verticalCenter
    text: row.title
    color: row.foreground
    font.family: row.fontFamily
    font.pixelSize: pxBody()
    font.bold: row.checked
  }
  Text {
    anchors.left: icon.right
    anchors.leftMargin: sp()
    anchors.right: row.right
    anchors.rightMargin: sp() * 2
    anchors.top: icon.bottom
    font.family: row.fontFamily
    font.pixelSize: Math.max(9, pxBody() - 2)
    color: Qt.darker(row.foreground, 1.3)
    text: row.subtitle
    elide: Text.ElideRight
  }
  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: row.activate()
  }
}
