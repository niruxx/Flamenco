import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: I18n.tr("Effects")
    subtitle: I18n.tr("Shape the motion, atmosphere, and rhythm of your desktop. Changes apply live.")
    // Existing appearance keys remain compatible with saved configurations.
    readonly property var a: Settings.data.appearance

    FCard {
        Layout.fillWidth: true
        implicitHeight: Math.round(150 * Theme.scale)
        radius: Theme.rXl
        color: Theme.accentContainer
        property real phase: 1
        id: preview
        RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.sp5
            spacing: Theme.sp4
            Rectangle {
                Layout.preferredWidth: Math.round(64 * Theme.scale)
                Layout.preferredHeight: Math.round(64 * Theme.scale)
                radius: height / 2 - Theme.travel(8) * (1 - preview.phase)
                color: Theme.accent
                opacity: 0.3 + 0.7 * preview.phase
                scale: 1 - 0.15 * (1 - preview.phase) * (Theme.spatialMotion() ? 1 : 0)
                FIcon { anchors.centerIn: parent; icon: "auto_awesome"; size: 30; color: Theme.onAccent }
            }
            ColumnLayout {
                Layout.fillWidth: true
                FText { Layout.fillWidth: true; text: I18n.tr("A little motion, a lot of personality"); wrapMode: Text.Wrap; font.pixelSize: Theme.fsXl; font.weight: Font.DemiBold; color: Theme.onAccentContainer }
                FText { Layout.fillWidth: true; text: I18n.tr("Tune the timing below, then replay the entrance."); wrapMode: Text.Wrap; color: Theme.onAccentContainer; font.pixelSize: Theme.fsSm }
            }
            FIconButton {
                icon: "replay"
                accessibleName: I18n.tr("Replay motion preview")
                active: true
                onClicked: { preview.phase = 0; replay.restart(); }
            }
        }
        Anim { id: replay; target: preview; property: "phase"; to: 1; motionRole: "enter"; area: "panels" }
    }

    Group {
        title: I18n.tr("Motion & behavior")
        SliderRow { title: I18n.tr("Animation speed"); subtitle: I18n.tr("0% turns animations off"); icon: "animation"; target: page.a; key: "animSpeed"; from: 0; to: 2; stepSize: 0.05; factor: 100; suffix: "%" }
        ChoiceRow {
            title: I18n.tr("Style")
            subtitle: page.a.motionStyle === "smooth" ? I18n.tr("Gentle easing, nothing overshoots") : page.a.motionStyle === "snappy" ? I18n.tr("Quick and crisp") : page.a.motionStyle === "minimal" ? I18n.tr("Short and plain, no hover zoom") : I18n.tr("Springy, with a little bounce (Material 3 Expressive)")
            icon: "motion_mode"
            target: page.a
            key: "motionStyle"
            options: [{ value: "expressive", label: I18n.tr("Expressive") }, { value: "smooth", label: I18n.tr("Smooth") }, { value: "snappy", label: I18n.tr("Snappy") }, { value: "minimal", label: I18n.tr("Minimal") }]
        }
        DropdownRow {
            title: I18n.tr("Panels open with")
            subtitle: I18n.tr("Quick settings, the calendar, the launcher and the other panels")
            icon: "open_in_full"
            target: page.a
            key: "panelEffect"
            options: [{ value: "bloom", label: I18n.tr("Bloom") }, { value: "rise", label: I18n.tr("Rise") }, { value: "fade", label: I18n.tr("Fade") }, { value: "slide", label: I18n.tr("Slide") }, { value: "zoom", label: I18n.tr("Zoom") }, { value: "none", label: I18n.tr("None") }]
        }
        ChoiceRow {
            title: I18n.tr("Notifications arrive with")
            icon: "notifications"
            target: page.a
            key: "notifEffect"
            options: [{ value: "slide", label: I18n.tr("Slide") }, { value: "fade", label: I18n.tr("Fade") }, { value: "pop", label: I18n.tr("Pop") }]
        }
        SwitchRow { title: I18n.tr("Ripple where you click"); icon: "touch_app"; target: page.a; key: "ripple" }
        SwitchRow { title: I18n.tr("Grow under the pointer"); subtitle: I18n.tr("Workspace dots, launcher icons…"); icon: "zoom_in"; target: page.a; key: "hoverZoom" }
        SwitchRow { title: I18n.tr("Smooth scrolling"); subtitle: page.a.smoothScroll ? I18n.tr("Lists glide and keep a little momentum (Flamenco's own scrolling)") : I18n.tr("Off: lists scroll the standard way, with niri's scroll speed and direction (Mouse & Touchpad)"); icon: "swap_vert"; target: page.a; key: "smoothScroll" }
        SettingRow {
            title: I18n.tr("Speed of each part")
            subtitle: I18n.tr("On top of the overall speed. Off removes that part's animations.")
            icon: "speed"
        }
        Repeater {
            model: [{ k: "control", label: I18n.tr("Quick settings"), icon: "tune" }, { k: "calendar", label: I18n.tr("Calendar panel"), icon: "calendar_month" }, { k: "panels", label: I18n.tr("Panels"), icon: "dashboard" }, { k: "notifications", label: I18n.tr("Notifications"), icon: "notifications" },
                { k: "bar", label: I18n.tr("Bar (appearing at login)"), icon: "toolbar" }, { k: "workspaces", label: I18n.tr("Workspace indicator"), icon: "view_week" },
                { k: "dock", label: I18n.tr("Dock (showing and hiding)"), icon: "dock_to_bottom" }, { k: "launcher", label: I18n.tr("Launcher results"), icon: "apps" },
                { k: "lock", label: I18n.tr("Lock screen"), icon: "lock" }]
            SettingRow {
                id: ar
                required property var modelData
                readonly property real v: Theme.areaSpeed(modelData.k)
                title: modelData.label
                subtitle: v <= 0 ? I18n.tr("Off") : v === 1 ? I18n.tr("Normal") : Math.round(v * 100) + "%"
                icon: modelData.icon
                FSlider {
                    width: 220
                    from: 0
                    to: 2
                    stepSize: 0.1
                    value: ar.v
                    onMoved: val => {
                        const all = Object.assign({}, page.a.motionAreas || {});
                        all[ar.modelData.k] = Math.round(val * 10) / 10;
                        page.a.motionAreas = all;
                    }
                }
            }
        }
        SettingRow {
            title: I18n.tr("Try it")
            subtitle: I18n.tr("Opens quick settings with these settings")
            icon: "play_circle"
            FButton {
                text: I18n.tr("Preview")
                variant: "tonal"
                onClicked: Panels.toggle("control", "")
            }
        }
    }


    Group {
        title: I18n.tr("Personality")
        ChoiceRow { title: I18n.tr("Page changes"); icon: "view_carousel"; target: page.a; key: "pageEffect"; options: [{ value: "slide", label: I18n.tr("Slide & fade") }, { value: "fade", label: I18n.tr("Crossfade") }, { value: "none", label: I18n.tr("Instant") }] }
        SliderRow { title: I18n.tr("Motion distance"); subtitle: I18n.tr("Travel distance for surface and page transitions"); icon: "open_in_full"; target: page.a; key: "effectDistance"; from: 0; to: 2; stepSize: 0.05; factor: 100; suffix: "%" }
        SliderRow { title: I18n.tr("Spring strength"); subtitle: I18n.tr("Overshoot of controls in Expressive mode"); icon: "waves"; target: page.a; key: "springStrength"; from: 0; to: 1; stepSize: 0.05; factor: 100; suffix: "%" }
        SwitchRow { title: I18n.tr("Ambient motion"); subtitle: I18n.tr("Decorative media rotation, weather drift, and charging effects"); icon: "blur_on"; target: page.a; key: "ambientMotion" }
    }

    Group {
        title: I18n.tr("Animation timing")
        SettingRow { title: I18n.tr("Base durations"); subtitle: I18n.tr("Milliseconds before global and area speed multipliers. Zero makes the effect instant."); icon: "timer" }
        Repeater {
            model: [{ key: "feedback", label: I18n.tr("Press & hover") }, { key: "color", label: I18n.tr("Colors") }, { key: "fade", label: I18n.tr("Content reveal") }, { key: "shape", label: I18n.tr("Shape changes") }, { key: "move", label: I18n.tr("Movement & pages") }, { key: "enter", label: I18n.tr("Entrances") }, { key: "exit", label: I18n.tr("Exits") }, { key: "palette", label: I18n.tr("Palette changes") }]
            SettingRow {
                id: timing
                required property var modelData
                title: modelData.label
                subtitle: Math.round(Theme.motionTiming[modelData.key]) + " ms"
                icon: "schedule"
                FSlider {
                    width: Math.round(220 * Theme.scale)
                    from: 0; to: 1500; stepSize: 10
                    accessibleName: timing.modelData.label
                    value: Theme.motionTiming[timing.modelData.key]
                    onMoved: value => {
                        const durations = Object.assign({}, page.a.motionDurations || {});
                        durations[timing.modelData.key] = Math.round(value);
                        page.a.motionDurations = durations;
                    }
                }
            }
        }
        SettingRow {
            title: I18n.tr("Restore timing defaults")
            subtitle: I18n.tr("Keeps your chosen effects and appearance")
            FButton { text: I18n.tr("Reset timing"); variant: "tonal"; onClicked: page.a.motionDurations = ({}) }
        }
    }

    Group {
        title: I18n.tr("Effect for each panel")
        Repeater {
            model: [{ key: "control", label: I18n.tr("Quick settings") }, { key: "calendar", label: I18n.tr("Calendar") }, { key: "launcher", label: I18n.tr("Launcher") }, { key: "clipboard", label: I18n.tr("Clipboard") }, { key: "volume", label: I18n.tr("Volume") }]
            SettingRow {
                id: effect
                required property var modelData
                title: modelData.label
                icon: "auto_awesome"
                FDropdown {
                    implicitWidth: Math.round(220 * Theme.scale)
                    current: (page.a.panelEffects || {})[effect.modelData.key] || "inherit"
                    options: [{ value: "inherit", label: I18n.tr("Use global effect") }, { value: "bloom", label: I18n.tr("Bloom") }, { value: "rise", label: I18n.tr("Rise") }, { value: "slide", label: I18n.tr("Slide") }, { value: "zoom", label: I18n.tr("Zoom") }, { value: "fade", label: I18n.tr("Fade") }, { value: "none", label: I18n.tr("None") }]
                    onSelected: value => {
                        const effects = Object.assign({}, page.a.panelEffects || {});
                        if (value === "inherit") delete effects[effect.modelData.key];
                        else effects[effect.modelData.key] = value;
                        page.a.panelEffects = effects;
                    }
                }
            }
        }
    }

    Group {
        title: I18n.tr("Glass & surface effects")
        SliderRow { title: I18n.tr("Glass highlights"); icon: "light_mode"; target: page.a; key: "materialStrength"; from: 0; to: 1.5; stepSize: 0.05; factor: 100; suffix: "%" }
        SliderRow { title: I18n.tr("Frosted wallpaper"); subtitle: I18n.tr("Blurred wallpaper backing for glass panels and dock"); icon: "blur_on"; target: page.a; key: "glassFrost"; from: 0; to: 1; stepSize: 0.05; factor: 100; suffix: "%" }
    }

    VisualizerSection {}
}
