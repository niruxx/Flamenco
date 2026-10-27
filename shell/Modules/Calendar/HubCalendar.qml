import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// The Hub's Calendar page: a full-size month (each day a tile with its events'
// colors and titles) on the left, the chosen day's agenda and what's coming up
// on the right. It fills the Hub's height.
Item {
    id: root

    property real fillHeight: 600
    implicitHeight: Math.max(420, fillHeight)

    property int monthOffset: 0
    // set once (not bound to the clock, which ticks every second)
    property date selected: new Date()
    readonly property date shown: {
        const [y, m] = todayKey.split("-").map(Number);
        return new Date(y, m - 1 + monthOffset, 1);
    }
    readonly property int lead: Time.lead(shown)             // the first day of the week (Settings → Region & Language)
    // today as "yyyy-mm-dd": the clock ticks every second, this only changes at midnight,
    // so the tiles don't all recompute every second
    readonly property string todayKey: Events.key(Time.now)
    readonly property string selectedKey: Events.key(selected)
    // the six weeks on show: day key → its events, worked out once per month/calendar change
    readonly property var byDay: {
        const out = {};
        for (let i = 0; i < 42; i++) {
            const d = new Date(shown.getFullYear(), shown.getMonth(), i - lead + 1);
            const list = Events.on(d);
            if (list.length)
                out[Events.key(d)] = list;
        }
        return out;
    }
    readonly property var day: Events.on(selected)
    readonly property bool isToday: selectedKey === todayKey
    // after the chosen day (a week ahead)
    readonly property var upcoming: {
        const out = [];
        for (let i = 1; i <= 7 && out.length < 5; i++) {
            const d = new Date(selected);
            d.setDate(d.getDate() + i);
            for (const e of Events.on(d))
                if (out.length < 5)
                    out.push(Object.assign({ day: new Date(d) }, e));
        }
        return out;
    }
    function goToday() {
        monthOffset = 0;
        selected = new Date();
    }

    component Card: Rectangle {
        radius: Theme.rXl
        color: Theme.alpha(Theme.text, 0.035)
        border.width: 1
        border.color: Theme.alpha(Theme.text, 0.07)
    }

    RowLayout {
        anchors.fill: parent
        spacing: Theme.sp3

        // ── the month ──
        Card {
            id: monthCard
            Layout.preferredWidth: root.width * 0.58
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: -2
                        FText { text: Qt.formatDate(root.shown, "MMMM"); font.pixelSize: 30; font.weight: Font.Bold }
                        FText { text: Qt.formatDate(root.shown, "yyyy"); color: Theme.accent; font.weight: Font.Bold }
                    }
                    FButton { visible: root.monthOffset !== 0 || !root.isToday; text: "Today"; icon: "today"; variant: "tonal"; onClicked: root.goToday() }
                    FIconButton { icon: "chevron_left"; size: 38; flat: false; onClicked: root.monthOffset-- }
                    FIconButton { icon: "chevron_right"; size: 38; flat: false; onClicked: root.monthOffset++ }
                }

                // weekdays
                Row {
                    Layout.fillWidth: true
                    Repeater {
                        model: Time.weekdays("short")
                        FText {
                            required property string modelData
                            required property int index
                            width: days.cellW + (index < 6 ? days.gap : 0)
                            text: modelData
                            leftPadding: 8
                            dim: true
                            font.pixelSize: Theme.fsXs
                            font.weight: Font.Bold
                        }
                    }
                }

                // six weeks of day tiles, filling the rest
                Grid {
                    id: days
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    // its height comes from the card, not from its tiles
                    Layout.preferredHeight: 100
                    columns: 7
                    spacing: gap
                    readonly property int gap: 6
                    readonly property real cellW: (width - gap * 6) / 7
                    readonly property real cellH: Math.max(36, (height - gap * 5) / 6)

                    Repeater {
                        model: 42
                        Rectangle {
                            id: cell
                            required property int index
                            readonly property date date: new Date(root.shown.getFullYear(), root.shown.getMonth(), index - root.lead + 1)
                            readonly property bool inMonth: date.getMonth() === root.shown.getMonth()
                            readonly property string key: Events.key(date)
                            readonly property bool today: key === root.todayKey
                            readonly property bool picked: key === root.selectedKey
                            readonly property var events: root.byDay[key] ?? []
                            width: days.cellW
                            height: days.cellH
                            radius: Theme.rMd
                            color: today ? Theme.accent : picked ? Theme.alpha(Theme.accent, 0.18) : hover.hovered ? Theme.alpha(Theme.text, 0.07) : inMonth ? Theme.alpha(Theme.text, 0.03) : "transparent"
                            border.width: picked && !today ? 2 : 0
                            border.color: Theme.accent
                            Behavior on color { CAnim { duration: Theme.durShort } }

                            FText {
                                x: 8
                                y: 6
                                text: cell.date.getDate()
                                color: cell.today ? Theme.onAccent : Theme.text
                                opacity: cell.inMonth ? 1 : 0.35
                                font.pixelSize: Theme.fsSm
                                font.weight: cell.today || cell.picked ? Font.Bold : Font.DemiBold
                            }
                            // its events: titles while there's room, colored lines otherwise
                            Column {
                                x: 6
                                width: parent.width - 12
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 6
                                spacing: 2
                                Repeater {
                                    model: cell.events.slice(0, cell.height > 70 ? 2 : 1)
                                    Rectangle {
                                        required property var modelData
                                        width: parent.width
                                        height: cell.height > 70 ? 16 : 4
                                        radius: height / 2
                                        color: cell.today ? Theme.onAccent : modelData.color || Theme.accent2
                                        opacity: cell.inMonth ? 0.9 : 0.4
                                        FText {
                                            visible: parent.height > 8
                                            anchors.fill: parent
                                            anchors.leftMargin: 6
                                            anchors.rightMargin: 4
                                            verticalAlignment: Text.AlignVCenter
                                            text: parent.modelData.title
                                            elide: Text.ElideRight
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
                                            color: cell.today ? Theme.accent : Theme.onAccent
                                        }
                                    }
                                }
                            }
                            FText {
                                visible: cell.events.length > (cell.height > 70 ? 2 : 1)
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 6
                                text: "+" + (cell.events.length - (cell.height > 70 ? 2 : 1))
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: cell.today ? Theme.onAccent : Theme.textDim
                            }
                            HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                onTapped: {
                                    root.selected = cell.date;
                                    if (!cell.inMonth)
                                        root.monthOffset += cell.date < root.shown ? -1 : 1;
                                }
                            }
                        }
                    }
                }
            }
            WheelHandler {
                onWheel: event => root.monthOffset -= monthNotches.take(event)
            }
            WheelSteps { id: monthNotches }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.sp3

            // ── the chosen day ──
            Card {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Rectangle {
                            Layout.preferredWidth: 62
                            Layout.preferredHeight: 62
                            radius: Theme.rLg
                            gradient: Gradient {
                                GradientStop { position: 0; color: Theme.accent }
                                GradientStop { position: 1; color: Theme.accent2 }
                            }
                            Column {
                                anchors.centerIn: parent
                                spacing: -4
                                FText { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDate(root.selected, "d"); font.pixelSize: 26; font.weight: Font.Bold; color: Theme.onAccent }
                                FText { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDate(root.selected, "MMM").toUpperCase(); font.pixelSize: Theme.fsXs; font.weight: Font.Bold; color: Theme.onAccent }
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            FText { text: root.isToday ? "Today" : Qt.formatDate(root.selected, "dddd"); font.pixelSize: Theme.fsXl; font.weight: Font.Bold }
                            FText { text: root.day.length ? root.day.length + (root.day.length === 1 ? " event" : " events") : "Nothing planned"; dim: true; font.pixelSize: Theme.fsSm }
                        }
                    }

                    // its events, scrolling if there are many
                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 8
                        model: root.day
                        boundsBehavior: Flickable.StopAtBounds
                        delegate: Rectangle {
                            required property var modelData
                            width: ListView.view.width
                            height: 54
                            radius: Theme.rLg
                            color: Theme.alpha(modelData.color || Theme.accent, 0.12)
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 12
                                spacing: 10
                                Rectangle { Layout.preferredWidth: 4; Layout.preferredHeight: 36; radius: 2; color: modelData.color || Theme.accent }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    FText { Layout.fillWidth: true; text: modelData.title; font.weight: Font.DemiBold; elide: Text.ElideRight }
                                    FText { Layout.fillWidth: true; text: Events.timeOf(modelData) + (modelData.location ? " · " + modelData.location : ""); dim: true; font.pixelSize: Theme.fsXs; elide: Text.ElideRight }
                                }
                            }
                        }
                        ColumnLayout {
                            anchors.centerIn: parent
                            width: parent.width - 20
                            visible: root.day.length === 0
                            spacing: 6
                            FIcon { Layout.alignment: Qt.AlignHCenter; icon: "event_available"; size: 40; color: Theme.textDim }
                            FText {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.Wrap
                                dim: true
                                text: Settings.data.calendar.sources.length ? "A free day" : "No calendars yet. Add one in Settings → Clock & Weather → Calendars."
                            }
                        }
                    }
                }
            }

            // ── after it ──
            Card {
                Layout.fillWidth: true
                visible: root.upcoming.length > 0
                implicitHeight: next.implicitHeight + 28
                ColumnLayout {
                    id: next
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 14
                    spacing: 6
                    FText { text: "Coming up"; font.weight: Font.Bold }
                    Repeater {
                        model: root.upcoming
                        RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 10
                            FText { Layout.preferredWidth: 64; text: Qt.formatDate(modelData.day, "ddd d"); color: Theme.accent; font.weight: Font.Bold; font.pixelSize: Theme.fsSm }
                            Rectangle { width: 8; height: 8; radius: 4; color: modelData.color || Theme.accent }
                            FText { Layout.fillWidth: true; text: modelData.title; elide: Text.ElideRight; font.pixelSize: Theme.fsSm }
                            FText { text: Events.timeOf(modelData); dim: true; font.pixelSize: Theme.fsXs }
                        }
                    }
                }
            }
        }
    }
}
