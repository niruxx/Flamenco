import QtQuick
import qs.Commons as F
import qs.Compat.Dms.Common

// Flamenco's version of DMS's bar pill: the plugin's content in a chip that
// matches Flamenco's bar (hover tint, rounded), with DMS's properties.
Item {
    id: root

    property var axis: null
    property string section: "center"
    property var popoutTarget: null
    property var parentScreen: null
    property real widgetThickness: 30
    property real barThickness: 48
    property real barSpacing: 4
    property var barConfig: null
    property var blurBarWindow: null
    property alias content: contentLoader.sourceComponent
    property bool isVerticalOrientation: axis?.isVertical ?? false
    property bool isFirst: false
    property bool isLast: false
    property real sectionSpacing: 0
    property bool enableBackgroundHover: true
    property bool enableCursor: true
    readonly property bool isMouseHovered: mouseArea.containsMouse
    property bool isLeftBarEdge: false
    property bool isRightBarEdge: false
    property bool isTopBarEdge: false
    property bool isBottomBarEdge: false
    property real crossEdgeExtension: 0
    readonly property real dpr: parentScreen?.devicePixelRatio ?? 1
    readonly property real horizontalPadding: 10
    readonly property real visualWidth: isVerticalOrientation ? widgetThickness : (contentLoader.item ? contentLoader.item.implicitWidth + horizontalPadding * 2 : 0)
    readonly property real visualHeight: isVerticalOrientation ? (contentLoader.item ? contentLoader.item.implicitHeight + horizontalPadding * 2 : 0) : widgetThickness
    readonly property alias visualContent: visualContent

    signal clicked
    signal rightClicked(real rootX, real rootY)
    signal wheel(var wheelEvent)

    function triggerRipple(sourceItem, mouseX, mouseY) {}

    width: visualWidth
    height: visualHeight
    implicitWidth: visualWidth
    implicitHeight: visualHeight

    Rectangle {
        id: visualContent
        anchors.fill: parent
        radius: root.isVerticalOrientation ? F.Theme.rMd : height / 2
        color: root.enableBackgroundHover && mouseArea.containsMouse ? F.Theme.alpha(F.Theme.text, mouseArea.pressed ? 0.14 : 0.08) : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        Loader {
            id: contentLoader
            anchors.centerIn: parent
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.enableCursor ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                const p = root.mapToItem(null, mouse.x, mouse.y);
                root.rightClicked(p.x, p.y);
            } else {
                root.clicked();
            }
        }
        onWheel: wheel => root.wheel(wheel)
    }
}
