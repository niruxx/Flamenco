pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Flamenco shim for Noctalia's I18n: its English strings (Assets/Translations/en.json).
Singleton {
    id: root

    readonly property bool isLoaded: true
    readonly property string langCode: "en"
    readonly property string fullLocaleCode: "en"
    readonly property var locale: Qt.locale()
    readonly property var availableLanguages: ["en"]
    readonly property var translations: {
        try {
            return JSON.parse(file.text());
        } catch (e) {
            return {};
        }
    }

    signal languageChanged

    function lookup(key) {
        let cur = translations;
        for (const p of String(key).split(".")) {
            if (cur === undefined || cur === null)
                return undefined;
            cur = cur[p];
        }
        return cur;
    }
    function tr(key, interpolations) {
        let t = lookup(key);
        if (typeof t !== "string")
            return "!!" + key + "!!";
        for (const k in (interpolations || {}))
            t = t.replace(new RegExp("\\{" + k + "\\}", "g"), interpolations[k]);
        return t;
    }
    function trp(key, count, interpolations) {
        const all = Object.assign({ count: count }, interpolations || {});
        return tr(count === 1 ? key : key + "-plural", all);
    }
    function hasTranslation(key) {
        return typeof lookup(key) === "string";
    }

    FileView {
        id: file
        path: Quickshell.shellDir + "/Compat/Noctalia/Assets/Translations/en.json"
        blockLoading: true
        printErrors: false
    }
}
