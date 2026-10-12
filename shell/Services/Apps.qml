pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Desktop entries, fuzzy search, launch-frequency ranking.
Singleton {
    id: root

    readonly property var all: DesktopEntries.applications.values.filter(e => !e.noDisplay).sort((a, b) => a.name.localeCompare(b.name))
    readonly property alias usage: usageAdapter

    function lookup(appId) {
        if (!appId)
            return null;
        const id = String(appId);
        const lower = id.toLowerCase();
        return DesktopEntries.byId(id) ?? DesktopEntries.byId(lower) ?? all.find(e => {
            const eid = (e.id || "").toLowerCase();
            return eid === lower || eid.endsWith("." + lower) || (e.startupClass || "").toLowerCase() === lower || e.name.toLowerCase() === lower;
        }) ?? null;
    }

    function iconFor(appId) {
        return lookup(appId)?.icon ?? appId;
    }

    function score(e, q) {
        const name = e.name.toLowerCase();
        let s = 0;
        if (name === q)
            s = 120;
        else if (name.startsWith(q))
            s = 100;
        else if (name.split(/[\s\-_.]/).some(w => w.startsWith(q)))
            s = 80;
        else if (name.includes(q))
            s = 60;
        else if ((e.genericName || "").toLowerCase().includes(q) || (e.keywords || []).some(k => k.toLowerCase().includes(q)))
            s = 45;
        else if ((e.comment || "").toLowerCase().includes(q))
            s = 25;
        else {
            // subsequence match
            let i = 0;
            for (const c of name)
                if (c === q[i])
                    i++;
            if (i === q.length)
                s = 15;
        }
        if (s > 0)
            s += Math.min(30, Math.log2(1 + (usageAdapter.counts[e.id] || 0)) * 6);
        return s;
    }

    function search(query) {
        const q = query.trim().toLowerCase();
        if (!q)
            return all.slice().sort((a, b) => (usageAdapter.counts[b.id] || 0) - (usageAdapter.counts[a.id] || 0) || a.name.localeCompare(b.name));
        return all.map(e => ({ e, s: score(e, q) })).filter(x => x.s > 0).sort((a, b) => b.s - a.s).map(x => x.e);
    }

    function launch(e) {
        if (!e)
            return;
        const c = Object.assign({}, usageAdapter.counts);
        c[e.id] = (c[e.id] || 0) + 1;
        usageAdapter.counts = c;
        if (e.runInTerminal)
            Quickshell.execDetached([Settings.data.general.terminal, "-e", ...e.command]);
        else
            e.execute();
    }

    FileView {
        path: Paths.stateDir + "/app-usage.json"
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                writeAdapter();
        }
        JsonAdapter {
            id: usageAdapter
            property var counts: ({})
        }
    }
}
