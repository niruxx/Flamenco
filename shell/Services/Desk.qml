pragma Singleton

import QtQuick
import Quickshell
import qs.Commons

// Desktop widgets: what can be added, and the ones placed on each screen
// (Settings.data.desktop.widgets). Arranged in the editor that quick settings
// opens (Panels.editWidgets), drawn by Modules/Desktop.
Singleton {
    id: root

    readonly property var cfg: Settings.data.desktop
    readonly property var catalog: [
        { type: "clock", name: "Clock", icon: "schedule", about: "The time and date, large" },
        { type: "weather", name: "Weather", icon: "partly_cloudy_day", about: "Now, and the next few days" },
        { type: "system", name: "System", icon: "monitoring", about: "Processor, memory and temperature" },
        { type: "media", name: "Now playing", icon: "music_note", about: "Cover art and controls" },
        { type: "calendar", name: "Calendar", icon: "calendar_month", about: "This month at a glance" },
        { type: "note", name: "Note", icon: "sticky_note_2", about: "Type a note right on the desktop" }
    ]

    function info(type) {
        return catalog.find(c => c.type === type) ?? { type, name: type, icon: "widgets", about: "" };
    }

    // the widgets on a screen; ones saved for a screen that isn't connected show on the first
    function on(screen) {
        const names = Quickshell.screens.map(s => s.name);
        const first = names[0] ?? "";
        return (cfg.widgets || []).filter(w => w.screen === screen || (!names.includes(w.screen) && screen === first));
    }

    // a stored 0–1 share of the screen → pixels, kept on screen and at least the shell's
    // edge distance (Theme.edge, the windows' gap) from its sides, like panels and the bar
    function px(share, total, size) {
        const m = Math.min(Theme.edge, Math.max(0, (total - size) / 2));
        return Math.max(m, Math.min(total - size - m, (Number(share) || 0) * total));
    }

    // where a dropped widget settles: on a grid of that same distance, and centered
    // when it's dropped close to the middle, so widgets line up with each other
    function snap(v, total, size) {
        const m = Math.min(Theme.edge, Math.max(0, (total - size) / 2));
        const step = Math.max(4, Theme.edge);
        const mid = (total - size) / 2;
        if (Math.abs(v - mid) < step * 1.5)
            return mid;
        const p = Math.round((v - m) / step) * step + m;
        return Math.max(m, Math.min(total - size - m, p));
    }

    function add(type, screen, x, y) {
        const id = Date.now().toString(36) + Math.floor(Math.random() * 1e4).toString(36);
        cfg.widgets = (cfg.widgets || []).concat([{ id, type, screen, x, y, size: "m", text: "" }]);
        return id;
    }

    // a free-ish spot for a widget added with a click instead of a drag
    function addHere(type, screen) {
        const n = on(screen).length;
        return add(type, screen, 0.04 + (n % 6) * 0.03, 0.08 + (n % 6) * 0.06);
    }

    function update(id, changes) {
        cfg.widgets = (cfg.widgets || []).map(w => w.id === id ? Object.assign({}, w, changes) : w);
    }

    function remove(id) {
        cfg.widgets = (cfg.widgets || []).filter(w => w.id !== id);
    }

    function clear(screen) {
        const gone = on(screen).map(w => w.id);
        cfg.widgets = (cfg.widgets || []).filter(w => !gone.includes(w.id));
    }
}
