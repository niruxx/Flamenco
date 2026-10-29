import QtQuick
import Quickshell.Widgets
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
    readonly property real intensity: Math.max(0, Math.min(1.5, strength * Theme.materialStrength))
    anchors.fill: parent
    visible: finish !== "flat"

    // Specular layers are clipped as one surface, including the broad reflections.
    ClippingRectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        visible: root.finish === "gloss" || root.finish === "liquid"

        Rectangle {
            anchors.fill: parent
            radius: root.radius
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.rgba(1, 1, 1, (root.finish === "gloss" ? 0.52 : Theme.dark ? 0.2 : 0.52) * root.intensity) }
                GradientStop { position: 0.22; color: Qt.rgba(1, 1, 1, (root.finish === "gloss" ? 0.22 : 0.06) * root.intensity) }
                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.015 * root.intensity) }
                GradientStop { position: 0.78; color: Theme.alpha(Theme.accent2, (root.finish === "gloss" ? 0.07 : 0.025) * root.intensity) }
                GradientStop { position: 1; color: Qt.rgba(1, 1, 1, (root.finish === "gloss" ? 0.2 : 0.12) * root.intensity) }
            }
        }
        // Aero's lens reflection: a broad, soft shoulder instead of a hard stripe.
        Rectangle {
            visible: root.finish === "gloss"
            x: -parent.width * 0.12
            y: -parent.height * 0.62
            width: parent.width * 1.24
            height: parent.height * 1.04
            radius: height / 2
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.75; color: Qt.rgba(1, 1, 1, 0.035 * root.intensity) }
                GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0.2 * root.intensity) }
            }
        }
        // Glass catches a narrow reflected light at opposing edges.
        Rectangle {
            anchors.fill: parent
            radius: root.radius
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.14 * root.intensity) }
                GradientStop { position: 0.12; color: "transparent" }
                GradientStop { position: 0.84; color: "transparent" }
                GradientStop { position: 1; color: Theme.alpha(Theme.accent3, 0.09 * root.intensity) }
            }
        }
        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, (Theme.dark ? 0.34 : 0.8) * Math.min(1, root.intensity))
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, root.radius - 1)
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(0, 0, 0, (Theme.dark ? 0.2 : 0.07) * root.intensity)
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: Math.max(0, root.radius - 2)
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.07 * root.intensity)
        }
    }

    // ── chrome ──
    Rectangle {
        visible: root.finish === "chrome"
        anchors.fill: parent
        radius: root.radius
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.38 * root.intensity) }
            GradientStop { position: 0.22; color: Qt.rgba(1, 1, 1, 0.08 * root.intensity) }
            GradientStop { position: 0.55; color: Qt.rgba(0, 0, 0, 0.14 * root.intensity) }
            GradientStop { position: 0.8; color: Qt.rgba(1, 1, 1, 0.04) }
            GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0.22 * root.intensity) }
        }
    }
    Rectangle {
        visible: root.finish === "chrome"
        anchors.fill: parent
        radius: root.radius
        opacity: 0.16 * root.intensity
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
        border.color: Qt.rgba(1, 1, 1, 0.5 * root.intensity)
    }
}
