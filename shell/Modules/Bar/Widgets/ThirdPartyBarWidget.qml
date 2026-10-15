import QtQuick
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

// A Noctalia or DMS plugin's bar widget ("tp:<kind>/<id>" in the bar's layout),
// made with what that plugin's own shell would give it. A widget that fails to
// load shows a small warning; why is in Settings → Plugins (3rd party).
Item {
    id: root

    property string key: ""
    property string screenName
    property int barLevel: 0
    readonly property var info: ThirdParty.barWidgets["tp:" + key] ?? null
    readonly property var plugin: ThirdParty.find(key)
    readonly property var screenObj: Quickshell.screens.find(s => s.name === screenName) ?? null
    property var widget: null
    property bool failed: false
    property bool barVisible: !!info && (failed || !widget || ((widget.barVisible ?? true) && widget.visible !== false))

    implicitWidth: failed || !widget ? warn.implicitWidth : Math.max(widget.implicitWidth, widget.width)
    implicitHeight: failed || !widget ? warn.implicitHeight : Math.max(widget.implicitHeight, widget.height)

    // which bar section it's in, as Noctalia and DMS name them
    function section() {
        let p = root.parent;
        while (p && p.barSide === undefined)
            p = p.parent;
        return ({ start: "left", center: "center", end: "right" })[p?.barSide ?? "center"] ?? "center";
    }

    function load() {
        if (widget) {
            widget.destroy();
            widget = null;
        }
        failed = false;
        if (!info || !plugin)
            return;
        const comp = Qt.createComponent("file://" + info.file);
        const make = () => {
            if (comp.status === Component.Error) {
                failed = true;
                ThirdParty.fail(key, "bar widget", comp.errorString());
                return;
            }
            const sec = section();
            const props = info.kind === "noctalia" ? {
                pluginApi: ThirdParty.noctaliaApi(key),
                screen: screenObj,
                widgetId: "plugin:" + plugin.id,
                section: sec,
                sectionWidgetIndex: 0,
                sectionWidgetsCount: 1
            } : {
                pluginId: plugin.id,
                pluginService: ThirdParty.dms(),
                axis: { isVertical: Theme.barVertical, edge: Settings.data.bar.position },
                section: sec,
                parentScreen: screenObj,
                widgetThickness: Theme.barHeight - 10,
                barThickness: Theme.barHeight
            };
            const obj = comp.createObject(holder, props);
            if (!obj) {
                failed = true;
                ThirdParty.fail(key, "bar widget", "couldn't create it");
                return;
            }
            if (info.kind === "noctalia") {
                const api = ThirdParty.noctaliaApi(key);
                if (api)
                    api.barWidget = comp;
            }
            widget = obj;
        };
        if (comp.status === Component.Loading)
            comp.statusChanged.connect(make);
        else
            make();
    }

    Component.onCompleted: Qt.callLater(load)
    onKeyChanged: Qt.callLater(load)
    onInfoChanged: if (!widget && info) Qt.callLater(load)
    Component.onDestruction: if (widget) widget.destroy()

    Item {
        id: holder
        anchors.centerIn: parent
        width: root.widget ? root.implicitWidth : 0
        height: root.widget ? root.implicitHeight : 0
    }

    FIcon {
        id: warn
        anchors.centerIn: parent
        visible: root.failed
        icon: "extension_off"
        size: 18
        color: Theme.error
    }
}
