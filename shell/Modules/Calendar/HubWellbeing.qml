import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// The dashboard's Digital wellbeing page: this week's screen time as bars (and
// earlier weeks with ‹ ›), then the most used apps for the day, week or month,
// each with its share and a timer button to give it a daily limit.
Item {
    id: root
    property real fillHeight: 600
    implicitHeight: Math.max(420, fillHeight)

    property int weekOffset: 0
    property string range: "week"            // day | week | month
    property string limitFor: ""             // the app whose limit menu is open
    readonly property var week: Wellbeing.weekKeys(weekOffset)
    readonly property var weekSecs: week.map(k => Wellbeing.dayTotal(k))
    readonly property int weekTotal: weekSecs.reduce((a, b) => a + b, 0)
    // the chart's scale: the next of 4 / 8 / 12 / 16… hours above the busiest day
    readonly property int topH: Math.max(4, Math.ceil(Math.max(...weekSecs) / 3600 / 4) * 4)
    readonly property var apps: Wellbeing.appsOver(range === "day" ? [Wellbeing.today] : range === "week" ? Wellbeing.weekKeys(0) : Wellbeing.lastDays(30)).slice(0, 8)
    function shortDate(k) {
        const p = k.split("-");
        return Number(p[1]) + "/" + Number(p[2]);
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.sp3

        // ── the week ──
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: weekCol.implicitHeight + Theme.sp4 * 2
            radius: Theme.rXl
            color: Theme.alpha(Theme.text, 0.04)
            ColumnLayout {
                id: weekCol
                anchors.fill: parent
                anchors.margins: Theme.sp4
                spacing: Theme.sp2
                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 0
                        FText { text: root.weekOffset === 0 ? "This week's screen time" : "Weekly screen time"; font.pixelSize: Theme.fsLg; font.weight: Font.Medium }
                        Row {
                            spacing: 6
                            FText { text: Wellbeing.fmt(root.weekTotal); font.pixelSize: Theme.fsXxl; font.weight: Font.Bold; color: Theme.accent }
                            FText { anchors.baseline: parent.children[0].baseline; text: "TOTAL"; dim: true; font.pixelSize: Theme.fsXs; font.weight: Font.Bold }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    FIconButton { icon: "chevron_left"; size: 32; onClicked: root.weekOffset++ }
                    FText { text: root.shortDate(root.week[0]) + " – " + root.shortDate(root.week[6]); font.weight: Font.Medium }
                    FIconButton { icon: "chevron_right"; size: 32; disabled: root.weekOffset === 0; opacity: disabled ? 0.35 : 1; onClicked: root.weekOffset = Math.max(0, root.weekOffset - 1) }
                }
                // the bars over hour lines
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 150
                    Repeater {
                        model: 4
                        Item {
                            required property int index
                            width: parent.width
                            y: (index / 3) * (parent.height - 22)
                            Rectangle { width: parent.width - 34; height: 1; color: Theme.alpha(Theme.text, 0.12) }
                            FText { x: parent.width - 28; y: -7; text: Math.round(root.topH * (1 - index / 3)) + "h"; dim: true; font.pixelSize: Theme.fsXs }
                        }
                    }
                    Row {
                        id: bars
                        width: parent.width - 40
                        height: parent.height - 22
                        spacing: Theme.sp2
                        Repeater {
                            model: 7
                            Item {
                                required property int index
                                readonly property int secs: root.weekSecs[index]
                                readonly property bool today: root.week[index] === Wellbeing.today
                                width: (bars.width - bars.spacing * 6) / 7
                                height: bars.height
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: Math.max(secs > 0 ? 4 : 0, parent.height * Math.min(1, secs / (root.topH * 3600)))
                                    radius: Theme.rSm
                                    color: today ? Theme.accent : Theme.alpha(Theme.accent, 0.4)
                                    Behavior on height { Anim { duration: Theme.durMed } }
                                }
                                HoverHandler { id: barHover }
                                FText {
                                    visible: barHover.hovered && parent.secs > 0
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    y: -18
                                    text: Wellbeing.fmt(parent.secs)
                                    font.pixelSize: Theme.fsXs
                                    font.weight: Font.Bold
                                }
                                FText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: parent.bottom
                                    anchors.topMargin: 4
                                    text: Qt.locale().dayName((Qt.locale().firstDayOfWeek + parent.index) % 7, Locale.ShortFormat)
                                    font.pixelSize: Theme.fsXs
                                    font.weight: parent.today ? Font.Bold : Font.Normal
                                    color: parent.today ? Theme.accent : Theme.textDim
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── most used apps ──
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Theme.rXl
            color: Theme.alpha(Theme.text, 0.04)
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.sp4
                spacing: Theme.sp2
                RowLayout {
                    Layout.fillWidth: true
                    FText { Layout.fillWidth: true; text: "Most used apps"; font.pixelSize: Theme.fsLg; font.weight: Font.Medium }
                    FSegmented {
                        implicitWidth: 240
                        options: [{ value: "day", label: "Day" }, { value: "week", label: "Week" }, { value: "month", label: "Month" }]
                        current: root.range
                        onSelected: v => root.range = v
                    }
                }
                FScroll {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: appCol.implicitHeight
                    ColumnLayout {
                        id: appCol
                        width: parent.width
                        spacing: 3
                        FText {
                            visible: root.apps.length === 0
                            Layout.topMargin: Theme.sp3
                            text: Wellbeing.enabled ? "Nothing yet: time counts while you use apps" : "Screen time is off (Settings → Digital wellbeing)"
                            dim: true
                        }
                        Repeater {
                            model: root.apps
                            Rectangle {
                                id: arow
                                required property var modelData
                                required property int index
                                readonly property int limit: (Settings.data.wellbeing.limits || {})[modelData.id] ?? 0
                                Layout.fillWidth: true
                                implicitHeight: root.limitFor === modelData.id ? 96 : 56
                                Behavior on implicitHeight { Anim { duration: Theme.durShort } }
                                radius: index === 0 ? Theme.rLg : 6
                                color: Theme.alpha(Theme.text, 0.05)
                                RowLayout {
                                    x: Theme.sp3
                                    width: parent.width - Theme.sp3 * 2
                                    height: 56
                                    spacing: Theme.sp3
                                    AppIcon { implicitSize: 32; name: Apps.iconFor(arow.modelData.id) }
                                    FText { Layout.preferredWidth: 140; text: Wellbeing.appName(arow.modelData.id); font.weight: Font.Medium; elide: Text.ElideRight; wrapMode: Text.Wrap; maximumLineCount: 2 }
                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: 8
                                        radius: 4
                                        color: Theme.alpha(Theme.text, 0.1)
                                        Rectangle {
                                            width: parent.width * arow.modelData.seconds / Math.max(1, root.apps[0].seconds)
                                            height: parent.height
                                            radius: 4
                                            color: arow.limit > 0 && root.range === "day" && arow.modelData.seconds >= arow.limit * 60 ? Theme.error : Theme.accent
                                        }
                                    }
                                    FText { text: Wellbeing.fmt(arow.modelData.seconds); mono: true; Layout.preferredWidth: 72; horizontalAlignment: Text.AlignRight }
                                    FIconButton {
                                        icon: arow.limit > 0 ? "timer" : "timer_off"
                                        iconColor: arow.limit > 0 ? Theme.accent : Theme.textDim
                                        size: 32
                                        onClicked: root.limitFor = root.limitFor === arow.modelData.id ? "" : arow.modelData.id
                                    }
                                }
                                // a daily limit for it
                                Row {
                                    visible: root.limitFor === arow.modelData.id
                                    x: Theme.sp3
                                    y: 56
                                    spacing: 6
                                    FText { anchors.verticalCenter: parent.verticalCenter; text: "Daily limit:"; dim: true; font.pixelSize: Theme.fsSm }
                                    Repeater {
                                        model: [{ m: 0, l: "None" }, { m: 30, l: "30m" }, { m: 60, l: "1h" }, { m: 120, l: "2h" }, { m: 240, l: "4h" }]
                                        FButton {
                                            required property var modelData
                                            text: modelData.l
                                            variant: arow.limit === modelData.m ? "filled" : "text"
                                            implicitHeight: 30
                                            onClicked: {
                                                Wellbeing.setLimit(arow.modelData.id, modelData.m);
                                                root.limitFor = "";
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
