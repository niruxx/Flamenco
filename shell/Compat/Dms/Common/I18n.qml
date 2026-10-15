pragma Singleton

import QtQuick
import Quickshell

// Flamenco shim for DMS's I18n: plugins' strings are shown as written (English).
Singleton {
    readonly property string locale: Qt.locale().name
    readonly property bool isRtl: Qt.locale().textDirection === Qt.RightToLeft
    readonly property bool translationsLoaded: true

    function tr(term, context, isRealContext) {
        return term;
    }
    function trFor(pluginId, term, context, isRealContext) {
        return term;
    }
}
