import QtQuick
import Quickshell
import Quickshell.Io
import qs.Compat.Dms.Common
import qs.Services as FS

// Flamenco's version of DMS's PluginComponent, the root of a DMS bar widget.
// Same properties; the pill is drawn in Flamenco's style and the popout opens
// in Flamenco's panel for 3rd-party plugins.
Item {
    id: root

    property string layerNamespacePlugin: "plugin"
    property var axis: null
    property string section: "center"
    property var parentScreen: null
    property real widgetThickness: 30
    property real barThickness: 48
    property real barSpacing: 4
    property var barConfig: null
    property var blurBarWindow: null
    property string pluginId: ""
    property var pluginService: null
    property bool isFirst: false
    property bool isLast: false
    property bool isLeftBarEdge: false
    property bool isRightBarEdge: false
    property bool isTopBarEdge: false
    property bool isBottomBarEdge: false
    property real sectionSpacing: 0
    property real crossEdgeExtension: 0
    property string visibilityCommand: ""
    property int visibilityInterval: 0
    property bool conditionVisible: true
    property bool _visibilityOverride: false
    property bool _visibilityOverrideValue: true
    readonly property bool effectiveVisible: _visibilityOverride ? _visibilityOverrideValue : (!visibilityCommand || conditionVisible)

    property Component horizontalBarPill: null
    property Component verticalBarPill: null
    property Component popoutContent: null
    property real popoutWidth: 400
    property real popoutHeight: 0
    property var pillClickAction: null
    property var pillRightClickAction: null

    property Component controlCenterWidget: null
    property string ccWidgetIcon: ""
    property string ccWidgetPrimaryText: ""
    property string ccWidgetSecondaryText: ""
    property bool ccWidgetIsActive: false
    property bool ccWidgetIsToggle: true
    property Component ccDetailContent: null
    property real ccDetailHeight: 250
    signal ccWidgetToggled
    signal ccWidgetExpanded

    property var pluginData: ({})
    property var variants: []
    readonly property bool isVertical: axis?.isVertical ?? false
    readonly property bool hasHorizontalPill: horizontalBarPill !== null
    readonly property bool hasVerticalPill: verticalBarPill !== null
    readonly property bool hasPopout: popoutContent !== null
    readonly property int iconSize: Theme.barIconSize(barThickness, -4, root.barConfig?.maximizeWidgetIcons, root.barConfig?.iconScale)
    readonly property int iconSizeLarge: Theme.barIconSize(barThickness, undefined, root.barConfig?.maximizeWidgetIcons, root.barConfig?.iconScale)
    // false hides it in Flamenco's bar and frees its slot
    readonly property bool barVisible: effectiveVisible && (isVertical ? hasVerticalPill : hasHorizontalPill)

    Component.onCompleted: {
        loadPluginData();
        if (visibilityCommand)
            Qt.callLater(checkVisibility);
    }
    onPluginServiceChanged: loadPluginData()
    onPluginIdChanged: loadPluginData()

    Connections {
        target: root.pluginService
        ignoreUnknownSignals: true
        function onPluginDataChanged(changedPluginId) {
            if (changedPluginId === root.pluginId)
                root.loadPluginData();
        }
    }

    function loadPluginData() {
        if (!pluginId) {
            pluginData = {};
            return;
        }
        pluginData = SettingsData.getPluginSettingsForPlugin(pluginId);
        variants = [];
    }
    function checkVisibility() {
        if (!visibilityCommand) {
            conditionVisible = true;
            return;
        }
        visibilityProcess.running = true;
    }
    function setVisibilityOverride(visible) {
        _visibilityOverride = true;
        _visibilityOverrideValue = visible;
    }
    function clearVisibilityOverride() {
        _visibilityOverride = false;
        if (visibilityCommand)
            checkVisibility();
    }
    onVisibilityCommandChanged: visibilityCommand ? Qt.callLater(checkVisibility) : conditionVisible = true

    Timer {
        interval: Math.max(1, root.visibilityInterval) * 1000
        repeat: true
        running: root.visibilityInterval > 0 && root.visibilityCommand !== "" && !root._visibilityOverride
        onTriggered: root.checkVisibility()
    }
    Process {
        id: visibilityProcess
        command: ["sh", "-c", root.visibilityCommand]
        onExited: code => root.conditionVisible = code === 0
    }

    function createVariant(variantName, variantConfig) {
        return null;
    }
    function removeVariant(variantId) {}
    function updateVariant(variantId, variantConfig) {}

    function pillAction(action, pill) {
        if (action.length === 0) {
            action();
            return;
        }
        const g = pill.mapToItem(null, 0, 0);
        const pos = SettingsData.getPopupTriggerPosition(g, root.parentScreen, root.barThickness, pill.width);
        action(pos.x, pos.y, pos.width, root.section, root.parentScreen);
    }

    function triggerPopout() {
        const pill = isVertical ? verticalPill : horizontalPill;
        if (pillClickAction) {
            pillAction(pillClickAction, pill);
            return;
        }
        if (hasPopout)
            FS.ThirdParty.togglePopout(root, pill);
    }
    function triggerHoverPopout(widgetHostId) {
        triggerPopout();
    }
    function closePopout() {
        FS.ThirdParty.closePanel();
    }

    width: isVertical ? (hasVerticalPill ? verticalPill.width : 0) : (hasHorizontalPill ? horizontalPill.width : 0)
    height: isVertical ? (hasVerticalPill ? verticalPill.height : 0) : (hasHorizontalPill ? horizontalPill.height : 0)
    implicitWidth: width
    implicitHeight: height

    BasePill {
        id: horizontalPill
        visible: !root.isVertical && root.hasHorizontalPill
        opacity: root.effectiveVisible ? 1 : 0
        axis: root.axis
        section: root.section
        parentScreen: root.parentScreen
        widgetThickness: root.widgetThickness
        barThickness: root.barThickness
        content: root.horizontalBarPill
        onClicked: root.triggerPopout()
        onRightClicked: if (root.pillRightClickAction) root.pillAction(root.pillRightClickAction, horizontalPill)
    }
    BasePill {
        id: verticalPill
        visible: root.isVertical && root.hasVerticalPill
        opacity: root.effectiveVisible ? 1 : 0
        axis: root.axis
        section: root.section
        parentScreen: root.parentScreen
        widgetThickness: root.widgetThickness
        barThickness: root.barThickness
        content: root.verticalBarPill
        isVerticalOrientation: true
        onClicked: root.triggerPopout()
        onRightClicked: if (root.pillRightClickAction) root.pillAction(root.pillRightClickAction, verticalPill)
    }
}
