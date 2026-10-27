import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// Settings → Digital wellbeing: screen time (counted per app while you're active,
// kept only on this computer), daily app limits, break reminders.
Page {
    id: page
    title: I18n.tr("Digital wellbeing")
    subtitle: I18n.tr("Screen time and app limits. Everything stays on this computer (~/.local/state/flamenco/wellbeing.json).")
    readonly property var w: Settings.data.wellbeing
    readonly property var limited: Object.keys(w.limits || {})
    property bool confirmClear: false

    // today at a glance
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 92
        radius: Math.max(12, Theme.rLg)
        color: Theme.alpha(Theme.surface, Math.min(1, Theme.settingsOp + 0.04))
        RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.sp4
            spacing: Theme.sp4
            ColumnLayout {
                spacing: 0
                FText { text: I18n.tr("Today"); dim: true; font.pixelSize: Theme.fsSm }
                FText { text: Wellbeing.fmt(Wellbeing.todayTotal); font.pixelSize: Theme.fsXxl; font.weight: Font.Bold; color: Theme.accent }
            }
            Item { Layout.fillWidth: true }
            // the top three today
            Repeater {
                model: Wellbeing.appsOver([Wellbeing.today]).slice(0, 3)
                ColumnLayout {
                    required property var modelData
                    spacing: 2
                    AppIcon { Layout.alignment: Qt.AlignHCenter; implicitSize: 28; name: Apps.iconFor(modelData.id) }
                    FText { Layout.alignment: Qt.AlignHCenter; text: Wellbeing.fmt(modelData.seconds); font.pixelSize: Theme.fsXs; mono: true }
                }
            }
            FButton {
                text: I18n.tr("Details")
                variant: "tonal"
                onClicked: {
                    Panels.settingsOpen = false;
                    Panels.openDashboard("wellbeing", "");
                }
            }
        }
    }

    Group {
        title: I18n.tr("Screen time")
        SwitchRow { title: I18n.tr("Count screen time"); subtitle: I18n.tr("How long each app is in front of you, while you're active"); icon: "hourglass_bottom"; target: page.w; key: "enabled" }
        SliderRow { visible: page.w.enabled; title: I18n.tr("Stop counting after"); subtitle: I18n.tr("This long without touching the keyboard or mouse (and while locked)"); icon: "timer"; target: page.w; key: "idleAfter"; from: 30; to: 600; stepSize: 30; factor: 1 / 60; decimals: 1; suffix: " min" }
        SettingRow {
            title: I18n.tr("Clear screen time")
            subtitle: page.confirmClear ? I18n.tr("All of it, for every day: sure?") : I18n.tr("Forget everything counted so far")
            icon: "delete_sweep"
            Row {
                spacing: 6
                FButton {
                    visible: !page.confirmClear
                    text: I18n.tr("Clear…")
                    variant: "text"
                    onClicked: page.confirmClear = true
                }
                FButton {
                    visible: page.confirmClear
                    text: I18n.tr("Clear it all")
                    onClicked: {
                        Wellbeing.clear();
                        page.confirmClear = false;
                    }
                }
                FButton {
                    visible: page.confirmClear
                    text: I18n.tr("Keep")
                    variant: "text"
                    onClicked: page.confirmClear = false
                }
            }
        }
    }

    Group {
        title: I18n.tr("Breaks")
        SettingRow {
            title: I18n.tr("Remind me to take a break")
            subtitle: page.w.breakEvery > 0 ? I18n.tr("After ") + page.w.breakEvery + " minutes of use without one" : I18n.tr("Off")
            icon: "self_improvement"
            FSegmented {
                implicitWidth: 300
                options: [{ value: 0, label: I18n.tr("Off") }, { value: 30, label: I18n.tr("30m") }, { value: 60, label: I18n.tr("1h") }, { value: 90, label: I18n.tr("90m") }, { value: 120, label: I18n.tr("2h") }]
                current: page.w.breakEvery ?? 0
                onSelected: v => page.w.breakEvery = v
            }
        }
    }

    Group {
        title: I18n.tr("App limits")
        SettingRow {
            visible: page.limited.length === 0
            title: I18n.tr("No limits yet")
            subtitle: I18n.tr("In the dashboard's Wellbeing page, press an app's timer to give it a daily limit")
            icon: "timer_off"
        }
        Repeater {
            model: page.limited
            SettingRow {
                id: lrow
                required property string modelData
                readonly property int mins: (page.w.limits || {})[modelData] ?? 0
                readonly property int used: Wellbeing.todayApps[modelData] ?? 0
                title: Wellbeing.appName(modelData)
                subtitle: Wellbeing.fmt(lrow.used) + " of " + Wellbeing.fmt(lrow.mins * 60) + " today" + (lrow.used >= lrow.mins * 60 ? " · time's up" : "")
                icon: "timer"
                Row {
                    spacing: 4
                    Repeater {
                        model: [{ m: 30, l: "30m" }, { m: 60, l: "1h" }, { m: 120, l: "2h" }, { m: 240, l: "4h" }]
                        FButton {
                            required property var modelData
                            text: modelData.l
                            variant: lrow.mins === modelData.m ? "filled" : "text"
                            implicitHeight: 30
                            onClicked: Wellbeing.setLimit(lrow.modelData, modelData.m)
                        }
                    }
                    FIconButton { anchors.verticalCenter: parent.verticalCenter; icon: "close"; size: 30; onClicked: Wellbeing.setLimit(lrow.modelData, 0) }
                }
            }
        }
    }
}
