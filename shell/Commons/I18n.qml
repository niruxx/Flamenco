pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The shell's language (Settings → Region & Language → Flamenco's language): its
// text is written in English and wrapped in I18n.tr("…"); a catalog per language
// (assets/i18n/<code>.json, English → translation) gives the translation, and
// anything not translated yet stays in English. "" follows the system language.
Singleton {
    id: root

    readonly property string choice: Settings.data.general.language || ""
    // the language's code: "es", "de"… (from the choice, else $LANG)
    readonly property string code: (choice || String(Quickshell.env("LANG") || "en")).replace(/[._@].*$/, "").split("_")[0].toLowerCase()
    // the languages there are catalogs for
    readonly property var languages: [
        { value: "en", label: "English" }, { value: "es", label: "Español" }
    ]
    // for dates, numbers and day names
    readonly property var locale: Qt.locale(choice ? choice : String(Quickshell.env("LANG") || "en_US").replace(/\..*$/, ""))
    property var catalog: ({})

    function tr(s) {
        return catalog[s] ?? s;
    }

    FileView {
        path: root.code && root.code !== "en" ? Quickshell.shellDir + "/assets/i18n/" + root.code + ".json" : ""
        onLoaded: {
            try {
                root.catalog = JSON.parse(text());
            } catch (e) {
                root.catalog = {};
            }
        }
        onLoadFailed: root.catalog = {}
        onPathChanged: if (path === "") root.catalog = {}
    }
}
