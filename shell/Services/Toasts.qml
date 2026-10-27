pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Small pop-ups when something changes (Settings → Notifications → Toasts):
// Caps Lock and Num Lock, the keyboard layout, the power profile, Wi-Fi and
// Bluetooth, Do Not Disturb, night light, keep awake and dark mode. One at a
// time; a new one takes the old one's place. Nothing for the first few seconds,
// while the shell sets everything up.
Singleton {
    id: root

    readonly property var cfg: Settings.data.toasts
    readonly property bool on: (cfg.enabled ?? true) && armed
    property bool armed: false
    // what's showing: { icon, text, sub, seq }
    property var current: null
    property int seq: 0

    function show(kind, icon, text, sub) {
        if (!on || !(cfg[kind] ?? true))
            return;
        current = { icon: icon, text: text, sub: sub || "", seq: ++seq };
        hide.restart();
    }
    function test() {
        const was = armed;
        armed = true;
        show("modes", "notifications_active", "Toasts are on", "Like this one");
        armed = was;
    }

    Timer {
        running: Settings.ready
        interval: 4000
        onTriggered: root.armed = true
    }
    Timer {
        id: hide
        interval: 1800
        onTriggered: root.current = null
    }

    // ── Caps Lock / Num Lock (the keyboards' lights, LockKeys) ──
    Connections {
        target: LockKeys
        function onChanged(key, on) {
            if (key === "caps")
                root.show("lockKeys", "keyboard_capslock", on ? "Caps Lock on" : "Caps Lock off");
            else
                root.show("lockKeys", "dialpad", on ? "Num Lock on" : "Num Lock off");
        }
    }

    // ── everything else, as it changes ──
    Connections {
        target: Niri
        function onCurrentLayoutChanged() {
            if (Niri.currentLayout)
                root.show("layout", "keyboard", Niri.currentLayout);
        }
    }
    Connections {
        target: Power
        function onProfileIdChanged() {
            root.show("powerProfile", Power.profileIcon, Power.profileName);
        }
    }
    Connections {
        target: Network
        function onWifiEnabledChanged() {
            root.show("connections", Network.wifiEnabled ? "wifi" : "wifi_off", Network.wifiEnabled ? "Wi-Fi on" : "Wi-Fi off");
        }
    }
    Connections {
        target: BluetoothState
        function onEnabledChanged() {
            root.show("connections", BluetoothState.enabled ? "bluetooth" : "bluetooth_disabled", BluetoothState.enabled ? "Bluetooth on" : "Bluetooth off");
        }
    }
    Connections {
        target: Settings.data.notifications
        function onDndChanged() {
            const dnd = Settings.data.notifications.dnd;
            root.show("modes", dnd ? "do_not_disturb_on" : "notifications", dnd ? "Do Not Disturb on" : "Do Not Disturb off", dnd ? "Only critical notifications pop up" : "");
        }
    }
    Connections {
        target: Toggles
        function onNightLightChanged() {
            root.show("modes", "nightlight", Toggles.nightLight ? "Night light on" : "Night light off");
        }
        function onCaffeineChanged() {
            root.show("modes", "coffee", Toggles.caffeine ? "Keeping awake" : "Keep awake off", Toggles.caffeine ? "The screen won't lock or turn off by itself" : "");
        }
    }
    Connections {
        target: Settings.data.appearance
        function onModeChanged() {
            const dark = Settings.data.appearance.mode !== "light";
            root.show("modes", dark ? "dark_mode" : "light_mode", dark ? "Dark mode" : "Light mode");
        }
    }
}
