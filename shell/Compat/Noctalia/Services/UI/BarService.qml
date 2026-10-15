pragma Singleton

import QtQuick
import Quickshell
import qs.Compat.Noctalia.Commons
import qs.Services as FS

// Flamenco shim for Noctalia's BarService: which way pills open and tooltips
// point, and opening a plugin's settings (in Settings → Plugins (3rd party)).
Singleton {
    id: root

    property int widgetsRevision: 0
    property bool isVisible: true

    function getPillDirection(widget) {
        try {
            if (widget.section === "left")
                return false;
            if (widget.section === "right")
                return true;
            return widget.sectionWidgetIndex < widget.sectionWidgetsCount / 2;
        } catch (e) {
            return false;
        }
    }
    function getTooltipDirection(screenName) {
        switch (Settings.getBarPositionForScreen(screenName)) {
        case "right": return "left";
        case "left": return "right";
        case "bottom": return "top";
        default: return "bottom";
        }
    }
    function openPluginSettings(screen, manifest) {
        if (manifest?.id)
            FS.ThirdParty.openSettings("noctalia/" + manifest.id);
    }
    function registerWidget(screenName, section, widgetId, index, item) {}
    function unregisterWidget(screenName, section, widgetId, index) {}
    function getWidget(screenName, section, widgetId, index) {
        return null;
    }
    function lookupWidget(widgetId, screenName) {
        return null;
    }
}
