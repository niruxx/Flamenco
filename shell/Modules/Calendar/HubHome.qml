import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

// The dashboard's Home (the "Hub" layout): a greeting over the wallpaper, then
// Flamenco's quick toggles and sliders, what's playing, what's next, the
// weather and the system at a glance.
ColumnLayout {
    id: root

    property string screenName
    property bool live: false                  // showing right now (the visualizer runs only then)
    signal openTab(string tab)
    spacing: Theme.sp3

    readonly property string firstName: {
        const n = (Quickshell.env("USER") || "").trim();
        return n ? n.charAt(0).toUpperCase() + n.slice(1) : "";
    }
    readonly property string greeting: {
        const h = Time.now.getHours();
        return (h < 5 ? "Good night" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening") + (firstName ? ", " + firstName : "");
    }

    // the visualizer and the disk ring only run while Home shows
    onLiveChanged: {
        if (live)
            Cava.users++;
        else
            Cava.users = Math.max(0, Cava.users - 1);
        if (live)
            SystemStats.detailed = true;
        else if (Panels.current !== "performance")
            SystemStats.detailed = false;
    }
    Component.onDestruction: if (live) Cava.users = Math.max(0, Cava.users - 1)

    component Card: Rectangle {
        radius: Theme.rXl
        color: Theme.alpha(Theme.text, 0.035)
        border.width: 1
        border.color: Theme.alpha(Theme.text, 0.07)
    }

    component Chip: Rectangle {
        property string icon
        property string text
        implicitWidth: chipRow.implicitWidth + 18
        implicitHeight: 26
        radius: 13
        color: Theme.alpha(Theme.shadow, 0.35)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.12)
        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: 5
            FIcon { anchors.verticalCenter: parent.verticalCenter; icon: parent.parent.icon; size: 14; fill: 1; color: "#ffffff" }
            FText { anchors.verticalCenter: parent.verticalCenter; text: parent.parent.text; color: "#ffffff"; font.pixelSize: Theme.fsXs; font.weight: Font.DemiBold }
        }
    }

    // ── hero: greeting over the blurred wallpaper ──
    ClippingRectangle {
        Layout.fillWidth: true
        implicitHeight: 156
        radius: Theme.rXl
        color: Theme.surfaceHigh

        Image {
            id: wall
            anchors.fill: parent
            source: Paths.toUrl(Wallpapers.forScreen(root.screenName))
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(640, 220)
            asynchronous: true
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            source: wall
            blurEnabled: true
            blur: 0.8
            blurMax: 48
            saturation: 0.15
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Theme.alpha(Theme.shadow, 0.55) }
                GradientStop { position: 1; color: Theme.alpha(Theme.shadow, 0.15) }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 24
            anchors.rightMargin: 30
            spacing: 22

            // avatar, ringed in the accent
            Rectangle {
                Layout.preferredWidth: 104
                Layout.preferredHeight: 104
                radius: 52
                color: Theme.accent
                ClippingRectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: width / 2
                    color: Theme.surfaceHigh
                    Image {
                        id: face
                        anchors.fill: parent
                        source: Paths.toUrl(Settings.data.general.avatar)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                    FText {
                        anchors.centerIn: parent
                        visible: face.status !== Image.Ready
                        text: root.firstName.charAt(0)
                        font.pixelSize: 40
                        font.weight: Font.Bold
                        color: Theme.accent
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                FText {
                    Layout.fillWidth: true
                    text: root.greeting
                    color: "#ffffff"
                    font.pixelSize: Theme.fsXxl
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }
                FText {
                    text: Time.date + "  ·  up " + SystemStats.uptimeText
                    color: Qt.rgba(1, 1, 1, 0.75)
                    font.pixelSize: Theme.fsSm
                }
                Flow {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    spacing: 6
                    Chip { visible: Power.hasBattery; icon: Power.charging ? "battery_charging_full" : "battery_full"; text: Power.percent + "%" }
                    Chip { icon: Network.icon; text: Network.label }
                    Chip { icon: Power.profileIcon; text: Power.profileName }
                    Chip { visible: Notifs.unread > 0; icon: "notifications"; text: Notifs.unread }
                }
            }

            // the time, large and light, and the weather
            ColumnLayout {
                spacing: 0
                FText {
                    Layout.alignment: Qt.AlignRight
                    text: Time.time
                    color: "#ffffff"
                    font.pixelSize: 68
                    font.weight: Font.Light
                }
                Row {
                    Layout.alignment: Qt.AlignRight
                    visible: Weather.ready
                    spacing: 6
                    FIcon { anchors.verticalCenter: parent.verticalCenter; icon: Weather.icon; size: 18; color: Theme.accent3; fill: 1 }
                    FText { anchors.verticalCenter: parent.verticalCenter; text: Math.round(Weather.temp) + "°  " + Weather.description; color: Qt.rgba(1, 1, 1, 0.85) }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.sp3

        // ── toggles and sliders ──
        ColumnLayout {
            Layout.preferredWidth: (root.width - Theme.sp3 * 2) * 0.37
            Layout.fillHeight: true
            spacing: Theme.sp3

            Card {
                Layout.fillWidth: true
                implicitHeight: tiles.implicitHeight + 32

                GridLayout {
                    id: tiles
                    anchors.fill: parent
                    anchors.margins: 16
                    columns: 3
                    rowSpacing: 12
                    columnSpacing: 12

                    FToggleTile {
                        Layout.fillWidth: true
                        icon: Network.icon
                        title: "Wi-Fi"
                        subtitle: Network.label
                        active: Network.wifiEnabled
                        tint: Theme.accent
                        hasMore: true
                        onClicked: Network.setWifi(!Network.wifiEnabled)
                        onMoreClicked: Panels.openControl("wifi", root.screenName)
                    }
                    FToggleTile {
                        Layout.fillWidth: true
                        icon: BluetoothState.icon
                        title: "Bluetooth"
                        subtitle: BluetoothState.label
                        active: BluetoothState.enabled
                        tint: Theme.accent2
                        hasMore: BluetoothState.available
                        onClicked: BluetoothState.setEnabled(!BluetoothState.enabled)
                        onMoreClicked: Panels.openControl("bluetooth", root.screenName)
                    }
                    FToggleTile {
                        Layout.fillWidth: true
                        icon: "do_not_disturb_on"
                        title: "Do not disturb"
                        subtitle: Notifs.dnd ? "On" : "Off"
                        active: Notifs.dnd
                        tint: Theme.accent3
                        onClicked: Notifs.setDnd(!Notifs.dnd)
                    }
                    FToggleTile {
                        Layout.fillWidth: true
                        icon: "coffee"
                        title: "Caffeine"
                        subtitle: Toggles.caffeine ? "Staying awake" : "Off"
                        active: Toggles.caffeine
                        tint: Theme.accent2
                        onClicked: Toggles.caffeine = !Toggles.caffeine
                    }
                    FToggleTile {
                        Layout.fillWidth: true
                        icon: "nightlight"
                        title: "Night light"
                        subtitle: Toggles.nightLight ? Settings.data.night.temperature + "K" : "Off"
                        active: Toggles.nightLight
                        tint: Theme.warning
                        onClicked: Toggles.setNightLight(!Toggles.nightLight)
                    }
                    FToggleTile {
                        Layout.fillWidth: true
                        icon: Audio.micMuted ? "mic_off" : "mic"
                        title: "Microphone"
                        subtitle: Audio.micMuted ? "Muted" : Audio.micInUse ? "Live" : "On"
                        active: !Audio.micMuted
                        tint: Theme.accent3
                        hasMore: true
                        onClicked: Audio.toggleMicMute()
                        onMoreClicked: Panels.openControl("mic", root.screenName)
                    }
                    FToggleTile {
                        Layout.fillWidth: true
                        icon: Power.profileIcon
                        title: "Power"
                        subtitle: Power.profileName
                        active: Power.profileName !== "Balanced"
                        tint: Theme.accent
                        hasMore: true
                        onClicked: Power.cycleProfile()
                        onMoreClicked: Panels.openControl("power", root.screenName)
                    }
                    FToggleTile {
                        Layout.fillWidth: true
                        icon: Theme.dark ? "dark_mode" : "light_mode"
                        title: "Dark mode"
                        subtitle: Theme.dark ? "On" : "Off"
                        active: Theme.dark
                        tint: Theme.accent2
                        onClicked: Settings.data.appearance.mode = Theme.dark ? "light" : "dark"
                    }
                    FToggleTile {
                        Layout.fillWidth: true
                        icon: "content_paste"
                        title: "Clipboard"
                        subtitle: Clipboard.entries.length ? Clipboard.entries.length + " items" : "History"
                        tint: Theme.accent3
                        onClicked: Panels.open("clipboard", root.screenName)
                    }
                    FToggleTile {
                        Layout.fillWidth: true
                        icon: Recorder.recording ? "stop_circle" : "screen_record"
                        title: Recorder.recording ? "Stop" : "Record"
                        subtitle: Recorder.recording ? Recorder.clock : "Screen · ⋯ area"
                        active: Recorder.recording
                        tint: Theme.error
                        hasMore: !Recorder.recording
                        onClicked: {
                            Panels.close();
                            Recorder.toggle("screen", root.screenName);
                        }
                        onMoreClicked: {
                            Panels.close();
                            Recorder.start("region", "");
                        }
                    }
                    FToggleTile {
                        Layout.fillWidth: true
                        icon: "screenshot_region"
                        title: "Screenshot"
                        subtitle: "Area · ⋯ screen"
                        tint: Theme.accent
                        hasMore: true
                        onClicked: {
                            Panels.close();
                            Quickshell.execDetached(["sh", "-c", 'sleep 0.4; exec "$1" screenshot region', "sh", Paths.bin]);
                        }
                        onMoreClicked: {
                            Panels.close();
                            Quickshell.execDetached(["sh", "-c", 'sleep 0.4; exec "$1" screenshot screen', "sh", Paths.bin]);
                        }
                    }
                    FToggleTile {
                        Layout.fillWidth: true
                        icon: "wallpaper"
                        title: "Wallpaper"
                        subtitle: Paths.fileName(Wallpapers.forScreen(root.screenName)) || "Pick one"
                        tint: Theme.accent2
                        onClicked: root.openTab("wallpapers")
                    }
                }
            }

            Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: sliders.implicitHeight + 32

                ColumnLayout {
                    id: sliders
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    FPillSlider {
                        Layout.fillWidth: true
                        icon: Audio.icon
                        value: Audio.volume
                        muted: Audio.muted
                        from: Theme.accent3
                        to: Theme.accent2
                        onMoved: v => Audio.setVolume(v)
                        onIconClicked: Audio.toggleMute()
                    }
                    FPillSlider {
                        Layout.fillWidth: true
                        icon: Audio.micMuted ? "mic_off" : "mic"
                        value: Audio.micVolume
                        muted: Audio.micMuted
                        from: Theme.warning
                        to: Theme.accent
                        onMoved: v => Audio.setMicVolume(v)
                        onIconClicked: Audio.toggleMicMute()
                    }
                    FPillSlider {
                        Layout.fillWidth: true
                        visible: Brightness.available
                        icon: "brightness_6"
                        value: Brightness.value
                        from: Theme.accent
                        to: Theme.warning
                        onMoved: v => Brightness.set(v)
                    }
                }
            }
        }

        // ── now playing, and what's next ──
        ColumnLayout {
            Layout.preferredWidth: (root.width - Theme.sp3 * 2) * 0.34
            Layout.fillHeight: true
            spacing: Theme.sp3

            ClippingRectangle {
                Layout.fillWidth: true
                implicitHeight: 248
                radius: Theme.rXl
                color: Theme.alpha(Theme.text, 0.035)

                Image {
                    id: artBg
                    anchors.fill: parent
                    source: Media.art
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(320, 320)
                    asynchronous: true
                    visible: false
                }
                MultiEffect {
                    anchors.fill: parent
                    visible: Media.active && Media.art !== ""
                    source: artBg
                    blurEnabled: true
                    blur: 1
                    blurMax: 64
                    brightness: -0.35
                    saturation: 0.2
                }

                // the visualizer, along the bottom
                Row {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 3
                    Repeater {
                        model: Cava.values.length ? Cava.values : new Array(16).fill(0.05)
                        Rectangle {
                            required property var modelData
                            width: 7
                            height: 4 + modelData * 44
                            radius: 2
                            anchors.bottom: parent.bottom
                            color: Theme.alpha(Theme.accent, 0.55)
                            Behavior on height { NumberAnimation { duration: 90 } }
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    anchors.bottomMargin: 30
                    spacing: 14
                    visible: Media.active

                    ClippingRectangle {
                        Layout.preferredWidth: 150
                        Layout.preferredHeight: 150
                        Layout.alignment: Qt.AlignTop
                        radius: Theme.rLg
                        color: Theme.surfaceHigh
                        Image {
                            anchors.fill: parent
                            source: Media.art
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                        FIcon {
                            anchors.centerIn: parent
                            visible: Media.art === ""
                            icon: "music_note"
                            size: 48
                            color: Theme.textDim
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 2

                        FText {
                            text: Media.player?.identity ?? ""
                            color: Theme.accent
                            font.pixelSize: Theme.fsXs
                            font.weight: Font.Bold
                        }
                        FText {
                            Layout.fillWidth: true
                            text: Media.title
                            font.pixelSize: Theme.fsLg
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                            color: Media.art !== "" ? "#ffffff" : Theme.text
                        }
                        FText {
                            Layout.fillWidth: true
                            text: Media.artist
                            elide: Text.ElideRight
                            color: Media.art !== "" ? Qt.rgba(1, 1, 1, 0.75) : Theme.textDim
                            font.pixelSize: Theme.fsSm
                        }
                        Item { Layout.fillHeight: true }
                        FSeekBar {
                            Layout.fillWidth: true
                            visible: Media.length > 0
                            position: Media.position
                            length: Media.length
                            seekable: Media.player?.canSeek ?? false
                            onSeek: f => Media.seek(f)
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            FText {
                                text: Media.fmt(Media.position)
                                mono: true
                                font.pixelSize: Theme.fsXs
                                color: Media.art !== "" ? Qt.rgba(1, 1, 1, 0.75) : Theme.textDim
                            }
                            Item { Layout.fillWidth: true }
                            FIconButton { icon: "skip_previous"; size: 34; iconColor: Media.art !== "" ? "#ffffff" : Theme.text; onClicked: Media.previous() }
                            FIconButton {
                                icon: Media.playing ? "pause" : "play_arrow"
                                size: 46
                                flat: false
                                active: true
                                onClicked: Media.toggle()
                            }
                            FIconButton { icon: "skip_next"; size: 34; iconColor: Media.art !== "" ? "#ffffff" : Theme.text; onClicked: Media.next() }
                        }
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    visible: !Media.active
                    spacing: 6
                    FIcon { Layout.alignment: Qt.AlignHCenter; icon: "music_off"; size: 36; color: Theme.textDim }
                    FText { Layout.alignment: Qt.AlignHCenter; text: "Nothing playing"; dim: true }
                }

                MouseArea {
                    anchors.fill: parent
                    z: -1
                    onClicked: root.openTab("media")
                }
            }

            // what's next today (calendars in Settings → Clock & Weather)
            Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: next.implicitHeight + 28

                readonly property var today: Events.on(Time.now).filter(e => e.allDay || new Date(e.end) >= Time.now)

                ColumnLayout {
                    id: next
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        FIcon { icon: "event_upcoming"; size: 20; color: Theme.accent }
                        FText { Layout.fillWidth: true; text: "Up next"; font.weight: Font.Bold; font.pixelSize: Theme.fsMd }
                        FText { text: Time.format("ddd d MMM"); color: Theme.accent; font.weight: Font.Bold }
                    }
                    Repeater {
                        model: parent.parent.today.slice(0, 4)
                        RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 10
                            Rectangle { width: 4; height: 30; radius: 2; color: modelData.color || Theme.accent }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                FText { Layout.fillWidth: true; text: modelData.title; elide: Text.ElideRight; font.weight: Font.DemiBold; font.pixelSize: Theme.fsSm }
                                FText { text: Events.timeOf(modelData) + (modelData.location ? " · " + modelData.location : ""); dim: true; font.pixelSize: Theme.fsXs }
                            }
                        }
                    }
                    FText {
                        visible: parent.parent.today.length === 0
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        dim: true
                        font.pixelSize: Theme.fsSm
                        text: Settings.data.calendar.sources.length ? "Nothing else today." : "Nothing today. Add calendars in Settings → Clock & Weather to see your events here."
                    }
                    Item { Layout.fillHeight: true }
                    FButton {
                        Layout.alignment: Qt.AlignRight
                        text: "Calendar"
                        icon: "calendar_month"
                        variant: "text"
                        onClicked: root.openTab("calendar")
                    }
                }
            }
        }

        // ── weather and the system ──
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.sp3

            Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: wx.implicitHeight + 28

                ColumnLayout {
                    id: wx
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    RowLayout {
                        spacing: 12
                        FIcon { icon: Weather.icon; size: 44; fill: 1; color: Theme.warning }
                        ColumnLayout {
                            spacing: 0
                            FText { text: Weather.ready ? Math.round(Weather.temp) + "°" : "—"; font.pixelSize: 36; font.weight: Font.Bold }
                            FText { text: Weather.ready ? Weather.description + " · feels " + Math.round(Weather.feelsLike) + "°" : "Loading…"; dim: true; font.pixelSize: Theme.fsSm }
                        }
                    }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: Weather.ready
                        Repeater {
                            model: [{ i: "location_on", t: Weather.place }, { i: "humidity_percentage", t: Weather.humidity + "%" }, { i: "air", t: Math.round(Weather.wind) + " km/h" }]
                            Rectangle {
                                required property var modelData
                                visible: !!modelData.t
                                implicitWidth: wr.implicitWidth + 16
                                implicitHeight: 24
                                radius: 12
                                color: Theme.alpha(Theme.text, 0.06)
                                Row {
                                    id: wr
                                    anchors.centerIn: parent
                                    spacing: 4
                                    FIcon { anchors.verticalCenter: parent.verticalCenter; icon: modelData.i; size: 13; color: Theme.accent }
                                    FText { anchors.verticalCenter: parent.verticalCenter; text: modelData.t; font.pixelSize: Theme.fsXs; font.weight: Font.DemiBold }
                                }
                            }
                        }
                    }
                    // the next hours
                    RowLayout {
                        Layout.fillWidth: true
                        visible: Weather.hourly.length > 0
                        Repeater {
                            model: Weather.hourly.filter((_, i) => i % 2 === 0).slice(0, 6)
                            ColumnLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 2
                                FText { Layout.alignment: Qt.AlignHCenter; text: Qt.formatTime(new Date(modelData.time), Settings.data.general.use24h ? "HH" : "h AP"); dim: true; font.pixelSize: Theme.fsXs }
                                FIcon { Layout.alignment: Qt.AlignHCenter; icon: Weather.iconFor(modelData.code, modelData.day); size: 18; color: Theme.warning }
                                FText { Layout.alignment: Qt.AlignHCenter; text: Math.round(modelData.temp) + "°"; font.pixelSize: Theme.fsXs; font.weight: Font.Bold }
                            }
                        }
                    }
                    Item { Layout.fillHeight: true }
                    // the next days, with their range on a shared scale
                    Repeater {
                        id: days
                        model: Weather.daily.slice(0, 3)
                        readonly property real lo: Math.min(...Weather.daily.slice(0, 3).map(d => d.min), 100)
                        readonly property real hi: Math.max(...Weather.daily.slice(0, 3).map(d => d.max), -100)
                        RowLayout {
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            spacing: 8
                            FText { Layout.preferredWidth: 42; text: index === 0 ? "Today" : Qt.formatDate(new Date(modelData.date), "ddd"); font.weight: Font.DemiBold; font.pixelSize: Theme.fsSm }
                            FIcon { icon: Weather.iconFor(modelData.code, true); size: 16; color: Theme.warning }
                            FText { text: Math.round(modelData.min) + "°"; dim: true; font.pixelSize: Theme.fsXs }
                            Rectangle {
                                Layout.fillWidth: true
                                height: 5
                                radius: 3
                                color: Theme.alpha(Theme.text, 0.08)
                                Rectangle {
                                    readonly property real span: Math.max(1, days.hi - days.lo)
                                    x: parent.width * (modelData.min - days.lo) / span
                                    width: Math.max(6, parent.width * (modelData.max - modelData.min) / span)
                                    height: parent.height
                                    radius: 3
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0; color: Theme.accent2 }
                                        GradientStop { position: 1; color: Theme.warning }
                                    }
                                }
                            }
                            FText { text: Math.round(modelData.max) + "°"; font.pixelSize: Theme.fsXs; font.weight: Font.Bold }
                        }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    z: -1
                    onClicked: root.openTab("weather")
                }
            }

            Card {
                Layout.fillWidth: true
                implicitHeight: 112

                readonly property var root_: SystemStats.disks.find(d => d.mount === "/") ?? SystemStats.disks[0] ?? null
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    FRing { Layout.fillWidth: true; value: SystemStats.cpu; text: Math.round(SystemStats.cpu * 100) + "%"; label: "CPU" }
                    FRing { Layout.fillWidth: true; value: SystemStats.mem; text: Math.round(SystemStats.mem * 100) + "%"; label: "RAM"; color: Theme.accent }
                    FRing { Layout.fillWidth: true; value: SystemStats.temp / 100; text: Math.round(SystemStats.temp) + "°"; label: "TEMP"; color: Theme.warning }
                    FRing {
                        Layout.fillWidth: true
                        readonly property var d: parent.parent.root_
                        value: d && d.size ? d.used / d.size : 0
                        text: d && d.size ? Math.round(d.used / d.size * 100) + "%" : "—"
                        label: "DISK"
                        color: Theme.accent3
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    z: -1
                    onClicked: root.openTab("system")
                }
            }
        }
    }
}
