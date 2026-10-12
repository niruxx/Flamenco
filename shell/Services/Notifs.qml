pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.Commons

// Notification daemon + popup queue + persistent history.
Singleton {
    id: root

    readonly property alias popups: popupModel
    readonly property alias history: historyModel
    readonly property bool dnd: Settings.data.notifications.dnd
    property var live: ({})
    property int unread: 0

    function setDnd(on) {
        Settings.data.notifications.dnd = on;
    }

    function entryFor(n) {
        return {
            nid: n.id,
            appName: n.appName || "",
            appIcon: n.appIcon || "",
            image: n.image || "",
            summary: n.summary || "",
            body: n.body || "",
            urgency: n.urgency === NotificationUrgency.Critical ? 2 : n.urgency === NotificationUrgency.Low ? 0 : 1,
            time: Date.now(),
            timeout: n.expireTimeout > 0 ? n.expireTimeout : 0,
            actionsJson: JSON.stringify((n.actions || []).map(a => ({ id: a.identifier, text: a.text })))
        };
    }

    function indexIn(model, nid) {
        for (let i = 0; i < model.count; i++)
            if (model.get(i).nid === nid)
                return i;
        return -1;
    }

    function hidePopup(nid) {
        const i = indexIn(popupModel, nid);
        if (i >= 0)
            popupModel.remove(i);
    }

    function dismiss(nid) {
        hidePopup(nid);
        const i = indexIn(historyModel, nid);
        if (i >= 0)
            historyModel.remove(i);
        live[nid]?.dismiss();
        delete live[nid];
        saveTimer.restart();
    }

    function invoke(nid, actionId) {
        const n = live[nid];
        const a = n?.actions?.find(x => x.identifier === actionId);
        a?.invoke();
        hidePopup(nid);
    }

    function clearAll() {
        for (const id in live)
            live[id]?.dismiss();
        live = {};
        popupModel.clear();
        historyModel.clear();
        unread = 0;
        saveTimer.restart();
    }

    function markRead() {
        unread = 0;
    }

    NotificationServer {
        keepOnReload: true
        actionsSupported: true
        bodyMarkupSupported: true
        bodySupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true;
            const e = root.entryFor(n);
            root.live[n.id] = n;
            n.closed.connect(() => delete root.live[n.id]);

            historyModel.insert(0, e);
            while (historyModel.count > 100)
                historyModel.remove(historyModel.count - 1);
            root.unread++;

            if (Settings.data.notifications.popups && (!root.dnd || e.urgency === 2)) {
                popupModel.insert(0, e);
                while (popupModel.count > 5)
                    popupModel.remove(popupModel.count - 1);
            }
            saveTimer.restart();
        }
    }

    ListModel { id: popupModel }
    ListModel { id: historyModel }

    // ── persistence (images from the bus can't survive a restart; drop them) ──
    FileView {
        id: store
        path: Paths.cacheDir + "/notifications.json"
        onLoaded: {
            try {
                const items = JSON.parse(text());
                for (const e of items)
                    historyModel.append(Object.assign({ timeout: 0, appIcon: "", appName: "", body: "", summary: "", urgency: 1, time: Date.now(), actionsJson: "[]" }, e, { image: "", nid: -Math.abs(e.nid || Math.random() * 1e9) }));
            } catch (err) {}
        }
    }

    Timer {
        id: saveTimer
        interval: 1000
        onTriggered: {
            const out = [];
            for (let i = 0; i < historyModel.count; i++) {
                const e = historyModel.get(i);
                out.push({ nid: e.nid, appName: e.appName, appIcon: e.appIcon, summary: e.summary, body: e.body, urgency: e.urgency, time: e.time, timeout: 0, image: "", actionsJson: "[]" });
            }
            store.setText(JSON.stringify(out));
        }
    }

    function ago(t) {
        const s = Math.floor((Date.now() - t) / 1000);
        if (s < 60)
            return "now";
        if (s < 3600)
            return Math.floor(s / 60) + "m";
        if (s < 86400)
            return Math.floor(s / 3600) + "h";
        return Math.floor(s / 86400) + "d";
    }
}
