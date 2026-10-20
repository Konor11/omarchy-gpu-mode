import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

// dan.gpu-mode — three-state GPU switch for Hybrid NVIDIA laptops.
//
// The dGPU (MX350-class) has no display outputs; the panel is wired to the
// iGPU. "Discrete" therefore means global PRIME render offload — every client
// renders on NVIDIA — not driving the display from it.
//
// Modes are stored in ~/.local/state/omarchy/gpu-mode and applied through
// ~/.local/state/omarchy/toggles/hypr/gpu-mode.lua (Omarchy loads every file
// in that directory on hyprctl reload).
BarWidget {
  id: root
  moduleName: "dan.gpu-mode"

  readonly property string script: Quickshell.env("HOME") + "/.config/omarchy/plugins/dan.gpu-mode/scripts/gpu-mode.sh"

  property string mode: "hybrid"
  property string gpuUtil: "--"
  property string gpuMem: ""
  property bool busy: false
  property bool popupOpen: false

  // Semantic mode colors — fixed so the three states stay distinguishable
  // across themes; text/labels use the theme palette.
  readonly property color integratedColor: "#5eead4"
  readonly property color hybridColor: "#fbbf24"
  readonly property color discreteColor: "#4ade80"

  function iconFor(m) {
    if (m === "integrated") return "\u25CB" // ○
    if (m === "nvidia") return "\u2B22"     // ⬢
    return "\u25D0"                         // ◐
  }
  function colorFor(m) {
    if (m === "integrated") return integratedColor
    if (m === "nvidia") return discreteColor
    return hybridColor
  }
  function labelFor(m) {
    if (m === "integrated") return "Integrated"
    if (m === "nvidia") return "Discrete"
    return "Hybrid"
  }
  function norm(t) {
    t = String(t || "").trim().toLowerCase()
    return (t === "integrated" || t === "hybrid" || t === "nvidia") ? t : "hybrid"
  }

  function refresh() {
    if (!modeProc.running) modeProc.running = true
    if (!statProc.running) statProc.running = true
  }
  function setMode(m) {
    if (busy) return
    busy = true
    setProc.command = [root.script, "set", m]
    setProc.running = true
  }
  function close() { popupOpen = false }

  visible: true
  implicitWidth: btn.implicitWidth
  implicitHeight: btn.implicitHeight

  ShellIpc {
    target: "dan.gpu-mode"
    function refresh(): void { root.broadcast("refresh") }
    function set(m: string): void { root.setMode(m) }
    function cycle(): void {
      root.setMode(root.mode === "integrated" ? "hybrid" : (root.mode === "hybrid" ? "nvidia" : "integrated"))
    }
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Process {
    id: modeProc
    command: [root.script, "get"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.mode = root.norm(text)
    }
  }

  Process {
    id: statProc
    command: ["bash", "-c", "nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var s = String(text || "").trim()
        if (!s) { root.gpuUtil = "--"; root.gpuMem = ""; return }
        var p = s.split(",").map(function(x) { return String(x).trim() })
        root.gpuUtil = p[0] + "%"
        root.gpuMem = p[1] + "/" + p[2] + " MiB" + (p[3] ? " · " + p[3] + "\u00B0C" : "")
      }
    }
  }

  Process {
    id: setProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.mode = root.norm(text)
        root.busy = false
        root.popupOpen = false
        statProc.running = true
      }
    }
    onExited: function(code) { if (code !== 0) root.busy = false }
  }

  BarIconButton {
    id: btn
    anchors.fill: parent
    bar: root.bar
    text: root.iconFor(root.mode)
    active: root.mode === "nvidia"
    tooltipText: "GPU: " + root.labelFor(root.mode) + (root.gpuUtil !== "--" ? " · " + root.gpuUtil : "") + "  (click — switch)"
    onPressed: function(b) {
      if (b === Qt.MiddleButton) {
        root.setMode(root.mode === "nvidia" ? "integrated" : "nvidia")
        return
      }
      root.popupOpen = !root.popupOpen
    }
  }

  Rectangle {
    parent: btn
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.rightMargin: 2
    anchors.bottomMargin: 2
    width: 6
    height: 6
    radius: 3
    color: root.colorFor(root.mode)
    border.color: Qt.rgba(0, 0, 0, 0.4)
    border.width: 1
    z: 2
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(320))
    contentHeight: popup.fittedContentHeight(col.implicitHeight)

    Column {
      id: col
      anchors.fill: parent
      spacing: Style.space(10)

      Text {
        textFormat: Text.PlainText
        text: "GPU mode"
        color: root.bar.foreground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.subtitle
        font.bold: true
      }

      Text {
        textFormat: Text.PlainText
        text: root.busy ? "Switching — Hyprland reload…" : ("MX350 · " + (root.gpuUtil !== "--" ? root.gpuUtil + (root.gpuMem ? " · " + root.gpuMem : "") : "idle"))
        color: Qt.darker(root.bar.foreground, 1.3)
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.bodySmall
      }

      // --- Integrated ---
      Rectangle {
        width: col.width
        height: Style.space(46)
        radius: Style.cornerRadius
        color: root.mode === "integrated" ? Qt.rgba(0.37, 0.92, 0.84, 0.12) : Qt.rgba(1, 1, 1, 0.04)
        border.color: root.mode === "integrated" ? root.integratedColor : Qt.rgba(1, 1, 1, 0.08)
        border.width: root.mode === "integrated" ? 2 : 1

        Text {
          anchors.left: parent.left
          anchors.leftMargin: Style.space(10)
          anchors.verticalCenter: parent.verticalCenter
          text: root.iconFor("integrated")
          color: root.integratedColor
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.title
        }
        Column {
          anchors.left: parent.left
          anchors.leftMargin: Style.space(38)
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(2)
          Text {
            textFormat: Text.PlainText
            text: "Integrated"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.body
            font.bold: root.mode === "integrated"
          }
          Text {
            textFormat: Text.PlainText
            text: "Intel only · dGPU bypassed · power saving"
            color: Qt.darker(root.bar.foreground, 1.3)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.bodySmall
          }
        }
        Text {
          anchors.right: parent.right
          anchors.rightMargin: Style.space(10)
          anchors.verticalCenter: parent.verticalCenter
          visible: root.mode === "integrated"
          text: "✓"
          color: root.integratedColor
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.title
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.setMode("integrated")
        }
      }

      // --- Hybrid ---
      Rectangle {
        width: col.width
        height: Style.space(46)
        radius: Style.cornerRadius
        color: root.mode === "hybrid" ? Qt.rgba(0.98, 0.75, 0.14, 0.12) : Qt.rgba(1, 1, 1, 0.04)
        border.color: root.mode === "hybrid" ? root.hybridColor : Qt.rgba(1, 1, 1, 0.08)
        border.width: root.mode === "hybrid" ? 2 : 1

        Text {
          anchors.left: parent.left
          anchors.leftMargin: Style.space(10)
          anchors.verticalCenter: parent.verticalCenter
          text: root.iconFor("hybrid")
          color: root.hybridColor
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.title
        }
        Column {
          anchors.left: parent.left
          anchors.leftMargin: Style.space(38)
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(2)
          Text {
            textFormat: Text.PlainText
            text: "Hybrid"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.body
            font.bold: root.mode === "hybrid"
          }
          Text {
            textFormat: Text.PlainText
            text: "Intel default · dGPU via prime-run · both visible"
            color: Qt.darker(root.bar.foreground, 1.3)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.bodySmall
          }
        }
        Text {
          anchors.right: parent.right
          anchors.rightMargin: Style.space(10)
          anchors.verticalCenter: parent.verticalCenter
          visible: root.mode === "hybrid"
          text: "✓"
          color: root.hybridColor
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.title
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.setMode("hybrid")
        }
      }

      // --- Discrete ---
      Rectangle {
        width: col.width
        height: Style.space(46)
        radius: Style.cornerRadius
        color: root.mode === "nvidia" ? Qt.rgba(0.29, 0.87, 0.50, 0.13) : Qt.rgba(1, 1, 1, 0.04)
        border.color: root.mode === "nvidia" ? root.discreteColor : Qt.rgba(1, 1, 1, 0.08)
        border.width: root.mode === "nvidia" ? 2 : 1

        Text {
          anchors.left: parent.left
          anchors.leftMargin: Style.space(10)
          anchors.verticalCenter: parent.verticalCenter
          text: root.iconFor("nvidia")
          color: root.discreteColor
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.title
        }
        Column {
          anchors.left: parent.left
          anchors.leftMargin: Style.space(38)
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(2)
          Text {
            textFormat: Text.PlainText
            text: "Discrete"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.body
            font.bold: root.mode === "nvidia"
          }
          Text {
            textFormat: Text.PlainText
            text: "All apps render on NVIDIA (PRIME offload)"
            color: Qt.darker(root.bar.foreground, 1.3)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.bodySmall
          }
        }
        Text {
          anchors.right: parent.right
          anchors.rightMargin: Style.space(10)
          anchors.verticalCenter: parent.verticalCenter
          visible: root.mode === "nvidia"
          text: "✓"
          color: root.discreteColor
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.title
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.setMode("nvidia")
        }
      }

      Text {
        width: col.width
        textFormat: Text.PlainText
        wrapMode: Text.WordWrap
        text: "Switch reloads Hyprland; existing windows keep old env — reopen them. Middle-click toggles Integrated ↔ Discrete."
        color: Qt.darker(root.bar.foreground, 1.5)
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.bodySmall
      }
    }
  }
}
