import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// App shortcuts: your pinned apps (the dock's, Settings → Dock) as a grid of
// icons on the desktop; click one to open it.
Grid {
    id: root
    property real k: 1
    property var spec
    property bool editing: false
    readonly property var apps: (Settings.data.dock.pinned || []).map(id => Apps.lookup(id)).filter(e => e)
    columns: Math.min(4, Math.max(1, apps.length))
    spacing: Math.round(Theme.sp3 * k)

    Repeater {
        model: root.apps
        Column {
            id: app
            required property var modelData
            spacing: Math.round(4 * root.k)
            width: Math.round(72 * root.k)
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.round(48 * root.k)
                height: width
                AppIcon {
                    anchors.fill: parent
                    implicitSize: parent.width
                    name: app.modelData.icon
                    scale: hit.containsMouse ? 1.1 : 1
                    Behavior on scale { Anim { duration: Theme.durShort; easing.bezierCurve: Theme.curves.springFast } }
                }
            }
            FText {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: app.modelData.name
                font.pixelSize: Math.round(Theme.fsXs * root.k)
                elide: Text.ElideRight
            }
            MouseArea {
                id: hit
                anchors.fill: parent
                enabled: !root.editing
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Apps.launch(app.modelData)
            }
        }
    }
    FText {
        visible: root.apps.length === 0
        text: "Pin apps in the dock or launcher to see them here"
        dim: true
        font.pixelSize: Math.round(Theme.fsSm * root.k)
    }
}
