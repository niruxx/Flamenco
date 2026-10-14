import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

// A plugin's bar widget: loads its QML file and hands it `api` (PluginApi).
// A file that fails to load shows a small warning instead of breaking the bar.
Item {
    id: root

    property string pluginId: ""
    property string screenName
    property int barLevel: 0
    readonly property var info: Plugins.barWidgets["plugin:" + pluginId] ?? null
    property bool barVisible: !!info && (loader.status !== Loader.Ready || (loader.item?.barVisible ?? true))

    implicitWidth: loader.status === Loader.Ready ? loader.item.implicitWidth : warn.implicitWidth
    implicitHeight: loader.status === Loader.Ready ? loader.item.implicitHeight : warn.implicitHeight

    PluginApi {
        id: api
        pluginId: root.pluginId
    }

    Loader {
        id: loader
        anchors.centerIn: parent
        active: !!root.info
        source: root.info ? "file://" + root.info.file : ""
        onLoaded: {
            item.api = api;
            if (item.screenName !== undefined)
                item.screenName = Qt.binding(() => root.screenName);
            if (item.barLevel !== undefined)
                item.barLevel = Qt.binding(() => root.barLevel);
        }
    }

    FIcon {
        id: warn
        anchors.centerIn: parent
        visible: loader.status === Loader.Error
        icon: "extension_off"
        size: 18
        color: Theme.error
    }
}
