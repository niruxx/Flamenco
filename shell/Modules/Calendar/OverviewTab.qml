import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

ColumnLayout {
    id: root
    signal openTab(string tab)
    spacing: Theme.sp3

    // clock + user
    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.sp3

        ColumnLayout {
            Layout.fillWidth: true
            spacing: -4
            RowLayout {
                spacing: 0
                FText { text: Time.hours; font.pixelSize: 52; font.weight: Font.Bold }
                FText {
                    text: ":"
                    font.pixelSize: 52
                    font.weight: Font.Bold
                    color: Theme.accent
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: Theme.speed > 0
                        NumberAnimation { to: 0.25; duration: 500; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1; duration: 500; easing.type: Easing.InOutSine }
                    }
                }
                FText { text: Time.minutes; font.pixelSize: 52; font.weight: Font.Bold }
            }
            FText { text: Time.date; dim: true }
        }

        // user
        Rectangle {
            visible: Settings.data.dashboard.showUser
            implicitWidth: userRow.implicitWidth + 20
            implicitHeight: 56
            radius: Theme.rLg
            color: Theme.surfaceHigh

            RowLayout {
                id: userRow
                anchors.centerIn: parent
                spacing: 10
                ClippingRectangle {
                    Layout.preferredWidth: 38
                    Layout.preferredHeight: 38
                    radius: 19
                    color: Theme.accent
                    FText {
                        anchors.centerIn: parent
                        visible: face.status !== Image.Ready
                        text: Paths.user.charAt(0).toUpperCase()
                        color: Theme.onAccent
                        font.weight: Font.Bold
                    }
                    Image {
                        id: face
                        anchors.fill: parent
                        source: Paths.toUrl(Settings.data.general.avatar)
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(76, 76)
                        asynchronous: true
                    }
                }
                ColumnLayout {
                    spacing: 0
                    FText { text: Paths.user; font.weight: Font.Bold }
                    FText { text: "up " + SystemStats.uptimeText; dim: true; font.pixelSize: Theme.fsXs }
                }
            }
        }
    }

    // calendar
    FCard {
        Layout.fillWidth: true
        implicitHeight: month.implicitHeight + Theme.sp4 * 2
        MonthGrid {
            id: month
            anchors.fill: parent
            anchors.margins: Theme.sp4
        }
    }

    // events on the selected day (Settings → Clock & Weather → Calendars)
    FCard {
        visible: Events.sources.length > 0
        Layout.fillWidth: true
        implicitHeight: evCol.implicitHeight + Theme.sp4 * 2
        ColumnLayout {
            id: evCol
            anchors.fill: parent
            anchors.margins: Theme.sp4
            spacing: Theme.sp2
            readonly property var dayEvents: Events.on(month.selected)
            RowLayout {
                Layout.fillWidth: true
                FText {
                    Layout.fillWidth: true
                    text: month.selected.toDateString() === Time.now.toDateString() ? "Today" : Qt.formatDate(month.selected, "dddd, d MMMM")
                    font.weight: Font.Bold
                }
                FIconButton {
                    icon: Events.loading ? "progress_activity" : "refresh"
                    size: 28
                    iconSize: 16
                    onClicked: Events.refresh(true)
                }
            }
            FText {
                visible: evCol.dayEvents.length === 0
                text: Events.loading ? "Loading…" : "Nothing planned"
                dim: true
                font.pixelSize: Theme.fsSm
            }
            Repeater {
                model: evCol.dayEvents
                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: Theme.sp3
                    Rectangle {
                        Layout.preferredWidth: 4
                        Layout.fillHeight: true
                        radius: 2
                        color: modelData.color || Theme.accent
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        FText { Layout.fillWidth: true; text: modelData.title; font.weight: Font.Medium; elide: Text.ElideRight }
                        FText {
                            Layout.fillWidth: true
                            text: Events.timeOf(modelData) + (modelData.location ? " · " + modelData.location : "") + (modelData.calendar ? " · " + modelData.calendar : "")
                            dim: true
                            font.pixelSize: Theme.fsXs
                            elide: Text.ElideRight
                        }
                    }
                }
            }
            FText {
                visible: Object.keys(Events.errors).length > 0
                Layout.fillWidth: true
                text: Object.keys(Events.errors).map(k => k + ": " + Events.errors[k]).join("\n")
                color: Theme.error
                font.pixelSize: Theme.fsXs
                wrapMode: Text.Wrap
            }
        }
    }

    // weather + media summaries
    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.sp3
        visible: weatherCard.visible || mediaCard.visible

        FCard {
            id: weatherCard
            visible: Settings.data.weather.enabled && Settings.data.weather.showInOverview
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            implicitHeight: 84

            RowLayout {
                anchors.fill: parent
                anchors.margins: Theme.sp3
                spacing: 10
                FIcon { icon: Weather.ready ? Weather.icon : "cloud_off"; size: 36; fill: 1; color: Theme.accent2 }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    FText {
                        text: Weather.ready ? Math.round(Weather.temp) + Weather.unit : (Settings.data.weather.city ? "Loading…" : "Set a city")
                        font.pixelSize: Theme.fsXl
                        font.weight: Font.Bold
                    }
                    FText {
                        Layout.fillWidth: true
                        text: Weather.ready ? Weather.description + " · " + Weather.place : "Settings → Clock & Weather"
                        dim: true
                        font.pixelSize: Theme.fsSm
                        elide: Text.ElideRight
                    }
                }
            }
            StateLayer { onClicked: root.openTab("weather") }
        }

        FCard {
            id: mediaCard
            visible: Settings.data.dashboard.showMedia
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            implicitHeight: 84

            RowLayout {
                anchors.fill: parent
                anchors.margins: Theme.sp3
                spacing: 10
                ClippingRectangle {
                    Layout.preferredWidth: 56
                    Layout.preferredHeight: 56
                    radius: Theme.rMd
                    color: Theme.surfaceHighest
                    Image {
                        anchors.fill: parent
                        source: Media.art
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize: Qt.size(112, 112)
                    }
                    FIcon { anchors.centerIn: parent; visible: !Media.art; icon: "music_note"; color: Theme.textDim }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    FText { Layout.fillWidth: true; text: Media.active ? Media.title : "No media playing"; font.weight: Font.Bold; elide: Text.ElideRight }
                    FText { Layout.fillWidth: true; text: Media.artist; dim: true; font.pixelSize: Theme.fsSm; elide: Text.ElideRight; visible: Media.active }
                }
                FIconButton {
                    visible: Media.active
                    icon: Media.playing ? "pause" : "play_arrow"
                    active: true
                    onClicked: Media.toggle()
                    z: 2
                }
            }
            StateLayer {
                z: -1
                onClicked: root.openTab("media")
            }
        }
    }
}
