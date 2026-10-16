import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

// The Hub's Weather page: the sky it is now (clear day, night, clouds, rain,
// snow, storm) filling the page, the temperature large, the details as glass
// chips, the next hours with their curve, and the week.
ClippingRectangle {
    id: root

    property real fillHeight: 600
    signal openSettings(string page)
    implicitHeight: Math.max(540, fillHeight)
    radius: Theme.rXl

    readonly property int code: Weather.code
    readonly property bool night: !Weather.isDay
    // what kind of sky, for its colors
    readonly property string sky: code >= 95 ? "storm" : (code >= 71 && code <= 77) || code === 85 || code === 86 ? "snow"
        : code >= 51 ? "rain" : code >= 45 ? "fog" : code >= 3 ? "cloud" : night ? "night" : "clear"
    readonly property var skies: ({
            clear: ["#3f8ed8", "#7cc0f0", "#f6c26b"],
            night: ["#0b1630", "#1f2d5c", "#3c3a73"],
            cloud: night ? ["#1b2233", "#33405a", "#56637d"] : ["#6c8299", "#9fb2c4", "#cfd8e0"],
            fog: ["#6d7378", "#9aa0a4", "#c4c8ca"],
            rain: night ? ["#101a2a", "#24364f", "#3c5470"] : ["#3d5368", "#5d7890", "#8ca2b5"],
            snow: ["#8aa1bd", "#bccbdc", "#eef3f8"],
            storm: ["#151524", "#2d2b45", "#5b4a6e"]
        })
    readonly property var colors: skies[sky] ?? skies.clear
    // dark text on pale skies
    readonly property bool pale: sky === "snow" || sky === "fog" || (sky === "cloud" && !night)
    readonly property color ink: pale ? "#1c2430" : "#ffffff"
    function ink_(a) {
        return Qt.rgba(ink.r, ink.g, ink.b, a);
    }
    function hhmm(iso) {
        return iso ? Qt.formatTime(new Date(iso), Settings.data.general.use24h ? "HH:mm" : "h:mm AP") : "—";
    }

    // the sky
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: root.colors[0] }
            GradientStop { position: 0.65; color: root.colors[1] }
            GradientStop { position: 1; color: root.colors[2] }
        }
    }
    // a sun or moon glow in the corner
    Rectangle {
        x: parent.width - width * 0.6
        y: -height * 0.4
        width: 420
        height: 420
        radius: 210
        visible: root.sky === "clear" || root.sky === "night"
        gradient: Gradient {
            GradientStop { position: 0; color: root.night ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 0.92, 0.6, 0.55) }
            GradientStop { position: 1; color: "transparent" }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 32
        spacing: 22
        visible: Weather.ready

        // ── now ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 26

            FIcon {
                icon: Weather.icon
                size: 120
                fill: 1
                color: root.ink
            }
            ColumnLayout {
                spacing: 0
                Row {
                    spacing: 6
                    FIcon { anchors.verticalCenter: parent.verticalCenter; icon: "location_on"; size: 18; fill: 1; color: root.ink_(0.85) }
                    FText { anchors.verticalCenter: parent.verticalCenter; text: Weather.place; color: root.ink_(0.85); font.pixelSize: Theme.fsMd; font.weight: Font.DemiBold }
                }
                FText {
                    text: Math.round(Weather.temp) + "°"
                    color: root.ink
                    font.pixelSize: 96
                    font.weight: Font.Light
                }
                FText {
                    text: Weather.description + "  ·  feels " + Math.round(Weather.feelsLike) + "°"
                    color: root.ink_(0.85)
                    font.pixelSize: Theme.fsLg
                }
            }
            Item { Layout.fillWidth: true }

            // details as glass chips
            GridLayout {
                columns: 2
                rowSpacing: 10
                columnSpacing: 10
                Repeater {
                    model: [
                        { i: "humidity_percentage", l: "Humidity", v: Weather.humidity + "%" },
                        { i: "air", l: "Wind", v: Math.round(Weather.wind) + " km/h" },
                        { i: "wb_twilight", l: "Sunrise", v: root.hhmm(Weather.sunrise) },
                        { i: "bedtime", l: "Sunset", v: root.hhmm(Weather.sunset) },
                        { i: "umbrella", l: "Rain today", v: (Weather.daily[0]?.rain ?? 0) + "%" },
                        { i: "thermostat", l: "Today", v: Math.round(Weather.daily[0]?.min ?? 0) + "° / " + Math.round(Weather.daily[0]?.max ?? 0) + "°" }
                    ]
                    Rectangle {
                        required property var modelData
                        implicitWidth: 168
                        implicitHeight: 62
                        radius: Theme.rLg
                        color: !root.pale ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.45)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.18)
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 10
                            FIcon { icon: modelData.i; size: 22; fill: 1; color: root.ink }
                            ColumnLayout {
                                spacing: 0
                                FText { text: modelData.l; color: root.ink_(0.7); font.pixelSize: Theme.fsXs }
                                FText { text: modelData.v; color: root.ink; font.weight: Font.Bold }
                            }
                        }
                    }
                }
            }
        }

        // ── the next hours, with their curve ──
        Rectangle {
            id: hoursCard
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 150
            radius: Theme.rXl
            color: !root.pale ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.4)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.16)

            readonly property var hours: Weather.hourly.slice(0, 12)
            readonly property real lo: Math.min(...hours.map(h => h.temp), 100)
            readonly property real hi: Math.max(...hours.map(h => h.temp), -100)

            Canvas {
                id: curve
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 18
                height: parent.height * 0.42
                readonly property var hours: parent.hours
                readonly property real lo: parent.lo
                readonly property real hi: parent.hi
                onHoursChanged: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const n = hours.length;
                    if (n < 2)
                        return;
                    const span = Math.max(1, hi - lo), step = width / n;
                    const pt = i => [step * (i + 0.5), height - 8 - (hours[i].temp - lo) / span * (height - 26)];
                    ctx.beginPath();
                    for (let i = 0; i < n; i++) {
                        const [x, y] = pt(i);
                        i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
                    }
                    ctx.lineWidth = 3;
                    ctx.lineJoin = "round";
                    ctx.strokeStyle = root.ink_(0.9);
                    ctx.stroke();
                    for (let i = 0; i < n; i++) {
                        const [x, y] = pt(i);
                        ctx.beginPath();
                        ctx.arc(x, y, 4, 0, Math.PI * 2);
                        ctx.fillStyle = root.ink;
                        ctx.fill();
                        ctx.fillStyle = root.ink;
                        ctx.font = "bold 13px sans-serif";
                        ctx.textAlign = "center";
                        ctx.fillText(Math.round(hours[i].temp) + "°", x, y - 10);
                    }
                }
            }
            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 18
                Repeater {
                    model: hoursCard.hours
                    ColumnLayout {
                        required property var modelData
                        width: parent.width / Math.max(1, hoursCard.hours.length)
                        spacing: 4
                        FIcon { Layout.alignment: Qt.AlignHCenter; icon: Weather.iconFor(modelData.code, modelData.day); size: 24; fill: 1; color: root.ink }
                        FText { Layout.alignment: Qt.AlignHCenter; text: modelData.rain > 0 ? modelData.rain + "%" : " "; color: root.ink_(0.7); font.pixelSize: Theme.fsXs }
                        FText { Layout.alignment: Qt.AlignHCenter; text: Qt.formatTime(new Date(modelData.time), Settings.data.general.use24h ? "HH:mm" : "h AP"); color: root.ink_(0.8); font.pixelSize: Theme.fsXs }
                    }
                }
            }
        }

        // ── the week ──
        RowLayout {
            id: weekRow
            Layout.fillWidth: true
            spacing: 10
            readonly property real lo: Math.min(...Weather.daily.map(d => d.min), 100)
            readonly property real hi: Math.max(...Weather.daily.map(d => d.max), -100)
            Repeater {
                id: week
                model: Weather.daily.slice(0, 7)
                Rectangle {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: 128
                    radius: Theme.rLg
                    color: index === 0 ? Qt.rgba(1, 1, 1, !root.pale ? 0.22 : 0.6) : Qt.rgba(1, 1, 1, !root.pale ? 0.1 : 0.4)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.16)
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 4
                        FText { Layout.alignment: Qt.AlignHCenter; text: index === 0 ? "Today" : Qt.formatDate(new Date(modelData.date), "ddd"); color: root.ink; font.weight: Font.Bold }
                        FIcon { Layout.alignment: Qt.AlignHCenter; icon: Weather.iconFor(modelData.code, true); size: 30; fill: 1; color: root.ink }
                        FText { Layout.alignment: Qt.AlignHCenter; text: Math.round(modelData.max) + "°  " + Math.round(modelData.min) + "°"; color: root.ink; font.pixelSize: Theme.fsSm; font.weight: Font.DemiBold }
                        // where today's range sits in the week's
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 4
                            radius: 2
                            color: root.ink_(0.15)
                            Rectangle {
                                readonly property real span: Math.max(1, weekRow.hi - weekRow.lo)
                                x: parent.width * (modelData.min - weekRow.lo) / span
                                width: Math.max(6, parent.width * (modelData.max - modelData.min) / span)
                                height: parent.height
                                radius: 2
                                color: root.ink_(0.85)
                            }
                        }
                    }
                }
            }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        visible: !Weather.ready
        spacing: 10
        FIcon { Layout.alignment: Qt.AlignHCenter; icon: "partly_cloudy_day"; size: 64; color: "#ffffff" }
        FText {
            Layout.alignment: Qt.AlignHCenter
            text: Settings.data.weather.enabled ? "Getting the weather…" : "Weather is off"
            color: "#ffffff"
            font.pixelSize: Theme.fsXl
            font.weight: Font.Bold
        }
        FButton {
            Layout.alignment: Qt.AlignHCenter
            text: "Weather settings"
            icon: "tune"
            onClicked: root.openSettings("clock")
        }
    }

    FIconButton {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 14
        icon: "tune"
        iconColor: root.ink
        onClicked: root.openSettings("clock")
    }
}
