import QtQuick
import qs.Commons

// The surface finish (Settings → Appearance → Shape & surfaces), laid over a
// rounded surface (the bar, panels, notifications, the dock…). Put it inside
// the Rectangle, before its content:
//   gloss   Frutiger Aero: a glassy highlight over the top half, a bright rim
//           along the top, a soft glow of the accent from below
//   chrome  Y2K: metallic bands, a light bevel on top and a dark one below, and
//           a faint iridescent sheen across
//   liquid  Liquid Glass: a soft sheen falling from the top, a light rim and a faint
//           inner edge, so see-through surfaces read as layered glass
//   flat    nothing
Item {
    id: root
    readonly property string finish: Settings.data.appearance.finish || "flat"
    property real radius: parent?.radius ?? 0
    property real strength: 1
    anchors.fill: parent
    visible: finish !== "flat"

    // ── gloss ──
    Rectangle {
        visible: root.finish === "gloss"
        anchors.fill: parent
        radius: root.radius
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.42 * root.strength) }
            GradientStop { position: 0.48; color: Qt.rgba(1, 1, 1, 0.12 * root.strength) }
            GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.02) }
            GradientStop { position: 1; color: Theme.alpha(Theme.accent, 0.14 * root.strength) }
        }
    }
    Rectangle {
        visible: root.finish === "gloss"
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.55 * root.strength)
    }

    // ── liquid glass ──
    Rectangle {
        visible: root.finish === "liquid"
        anchors.fill: parent
        radius: root.radius
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(1, 1, 1, (Theme.dark ? 0.16 : 0.42) * root.strength) }
            GradientStop { position: 0.32; color: Qt.rgba(1, 1, 1, (Theme.dark ? 0.04 : 0.12) * root.strength) }
            GradientStop { position: 0.7; color: Qt.rgba(1, 1, 1, 0) }
            GradientStop { position: 1; color: Qt.rgba(1, 1, 1, (Theme.dark ? 0.07 : 0.18) * root.strength) }
        }
    }
    // the rim: bright glass edge, and a faint dark line just inside it for depth
    Rectangle {
        visible: root.finish === "liquid"
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, (Theme.dark ? 0.28 : 0.7) * root.strength)
    }
    Rectangle {
        visible: root.finish === "liquid"
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, root.radius - 1)
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(0, 0, 0, (Theme.dark ? 0.25 : 0.06) * root.strength)
    }

    // ── chrome ──
    Rectangle {
        visible: root.finish === "chrome"
        anchors.fill: parent
        radius: root.radius
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.38 * root.strength) }
            GradientStop { position: 0.22; color: Qt.rgba(1, 1, 1, 0.08 * root.strength) }
            GradientStop { position: 0.55; color: Qt.rgba(0, 0, 0, 0.14 * root.strength) }
            GradientStop { position: 0.8; color: Qt.rgba(1, 1, 1, 0.04) }
            GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0.22 * root.strength) }
        }
    }
    Rectangle {
        visible: root.finish === "chrome"
        anchors.fill: parent
        radius: root.radius
        opacity: 0.16 * root.strength
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "#ff7ad9" }
            GradientStop { position: 0.35; color: "#8fe9ff" }
            GradientStop { position: 0.7; color: "#c3a6ff" }
            GradientStop { position: 1; color: "#ffd1f2" }
        }
    }
    Rectangle {
        visible: root.finish === "chrome"
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: 1.5
        border.color: Qt.rgba(1, 1, 1, 0.5 * root.strength)
    }
}
