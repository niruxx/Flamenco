import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// The Hub's Calendar page: the month on the left (days with events dotted),
// the chosen day's agenda on the right, and the next few days under it.
RowLayout {
    id: root
    spacing: Theme.sp3
    // as tall as the Hub (its cards stretch to it)
    property real fillHeight: 600
    implicitHeight: Math.max(520, fillHeight)

    readonly property var day: Events.on(month.selected)
    readonly property bool isToday: Events.key(month.selected) === Events.key(Time.now)
    // what's coming after the chosen day (a week ahead)
    readonly property var upcoming: {
        const out = [];
        for (let i = 1; i <= 7 && out.length < 5; i++) {
            const d = new Date(month.selected);
            d.setDate(d.getDate() + i);
            for (const e of Events.on(d))
                if (out.length < 5)
                    out.push(Object.assign({ day: new Date(d) }, e));
        }
        return out;
    }

    component Card: Rectangle {
        radius: Theme.rXl
        color: Theme.alpha(Theme.text, 0.035)
        border.width: 1
        border.color: Theme.alpha(Theme.text, 0.07)
    }

    Card {
        id: monthCard
        Layout.preferredWidth: root.width * 0.5
        Layout.fillHeight: true
        MonthGrid {
            id: month
            anchors.fill: parent
            anchors.margins: 20
            // six rows of days fill the card
            cellHeight: Math.max(44, Math.floor((monthCard.height - 40 - 96) / 6))
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Theme.sp3

        // the chosen day
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitHeight: agenda.implicitHeight + 32

            ColumnLayout {
                id: agenda
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    // the date, large, in an accent tile
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
                            FText { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDate(month.selected, "d"); font.pixelSize: 26; font.weight: Font.Bold; color: Theme.onAccent }
                            FText { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDate(month.selected, "MMM").toUpperCase(); font.pixelSize: Theme.fsXs; font.weight: Font.Bold; color: Theme.onAccent }
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        FText { text: root.isToday ? "Today" : Qt.formatDate(month.selected, "dddd"); font.pixelSize: Theme.fsXl; font.weight: Font.Bold }
                        FText { text: Qt.formatDate(month.selected, "d MMMM yyyy") + " · " + (root.day.length ? root.day.length + (root.day.length === 1 ? " event" : " events") : "free"); dim: true; font.pixelSize: Theme.fsSm }
                    }
                    FButton {
                        visible: !root.isToday
                        text: "Today"
                        icon: "today"
                        variant: "tonal"
                        onClicked: {
                            month.go(-month.monthOffset);
                            month.selected = Time.now;
                        }
                    }
                }

                Repeater {
                    model: root.day
                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 54
                        radius: Theme.rLg
                        color: Theme.alpha(modelData.color || Theme.accent, 0.12)
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 12
                            spacing: 10
                            Rectangle { Layout.preferredWidth: 4; Layout.preferredHeight: 38; radius: 2; color: modelData.color || Theme.accent }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                FText { Layout.fillWidth: true; text: modelData.title; font.weight: Font.DemiBold; elide: Text.ElideRight }
                                FText { Layout.fillWidth: true; text: Events.timeOf(modelData) + (modelData.location ? " · " + modelData.location : "") + (modelData.calendar ? " · " + modelData.calendar : ""); dim: true; font.pixelSize: Theme.fsXs; elide: Text.ElideRight }
                            }
                        }
                    }
                }
                ColumnLayout {
                    visible: root.day.length === 0
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    spacing: 4
                    FIcon { Layout.alignment: Qt.AlignHCenter; icon: "event_available"; size: 36; color: Theme.textDim }
                    FText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        dim: true
                        text: Settings.data.calendar.sources.length ? "Nothing on this day" : "No calendars yet: add one in Settings → Clock & Weather → Calendars"
                    }
                }
                Item { Layout.fillHeight: true }
            }
        }

        // after it
        Card {
            Layout.fillWidth: true
            visible: root.upcoming.length > 0
            implicitHeight: next.implicitHeight + 28
            ColumnLayout {
                id: next
                anchors.fill: parent
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
