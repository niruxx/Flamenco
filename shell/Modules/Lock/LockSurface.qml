import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

Item {
    id: root

    required property var ctx
    property string screenName: ""
    // 0 → 1 on lock, back to 0 while unlocking
    property real p: 0
    Component.onCompleted: p = 1
    Connections {
        target: root.ctx
        function onUnlockingChanged() {
            if (root.ctx.unlocking)
                root.p = 0;
        }
        function onLockedChanged() {
            if (root.ctx.locked)
                root.p = 1;
        }
    }
    Behavior on p { Anim { duration: Theme.durA("lock", 650); easing.bezierCurve: Theme.curves.emphasized } }

    // wallpaper, blurring in as we lock and clearing as we unlock so the
    // transition back to the desktop is seamless
    Image {
        id: wall
        anchors.fill: parent
        source: Wallpapers.stillUrl(Wallpapers.forScreen(root.screenName))
        sourceSize: Qt.size(width * Screen.devicePixelRatio, height * Screen.devicePixelRatio)
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: wall
        blurEnabled: true
        blurMax: 64
        blur: root.p
        brightness: -0.18 * root.p
        saturation: -0.1 * root.p
        scale: 1 + 0.06 * root.p
    }
    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        opacity: 0.25 * root.p
    }

    // clock
    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.16 - (1 - root.p) * 80
        opacity: root.p
        spacing: 0

        FText {
            Layout.alignment: Qt.AlignHCenter
            text: Time.hours + ":" + Time.minutes
            font.pixelSize: Theme.fsHuge * 1.4
            font.weight: Font.Black
            color: Theme.text
        }
        FText {
            Layout.alignment: Qt.AlignHCenter
            text: Time.date
            font.pixelSize: Theme.fsXl
            color: Theme.text
            opacity: 0.85
        }
    }

    // auth card
    ColumnLayout {
        id: auth
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.58 + (1 - root.p) * 120
        opacity: root.p
        spacing: Theme.sp4

        ClippingRectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 96
            Layout.preferredHeight: 96
            radius: 48
            color: Theme.accent
            border.width: 3
            border.color: Theme.alpha(Theme.text, 0.6)

            FText {
                anchors.centerIn: parent
                visible: avatar.status !== Image.Ready
                text: Paths.user.charAt(0).toUpperCase()
                font.pixelSize: 42
                font.weight: Font.Bold
                color: Theme.onAccent
            }
            Image {
                id: avatar
                anchors.fill: parent
                source: Paths.toUrl(Settings.data.general.avatar)
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(192, 192)
            }
        }

        FText {
            Layout.alignment: Qt.AlignHCenter
            text: Paths.user
            font.pixelSize: Theme.fsXl
            font.weight: Font.Bold
        }

        Rectangle {
            id: field
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 340
            Layout.preferredHeight: 54
            radius: 27
            color: Theme.alpha(Theme.surface, 0.75)
            border.width: 2
            border.color: root.ctx.errorText ? Theme.error : input.activeFocus ? Theme.accent : Theme.alpha(Theme.border, 0.6)
            Behavior on border.color { CAnim {} }

            // shake on failure
            transform: Translate { id: shake }
            SequentialAnimation {
                id: shakeAnim
                loops: 1
                NumberAnimation { target: shake; property: "x"; to: -16; duration: 50 }
                NumberAnimation { target: shake; property: "x"; to: 14; duration: 70 }
                NumberAnimation { target: shake; property: "x"; to: -10; duration: 70 }
                NumberAnimation { target: shake; property: "x"; to: 6; duration: 70 }
                NumberAnimation { target: shake; property: "x"; to: 0; duration: 70 }
            }
            Connections {
                target: root.ctx
                function onShakeCountChanged() { shakeAnim.restart(); }
                function onBufferChanged() {
                    if (input.text !== root.ctx.buffer)
                        input.text = root.ctx.buffer;
                }
            }

            TextInput {
                id: input
                anchors.fill: parent
                opacity: 0
                focus: true
                echoMode: TextInput.Password
                onTextEdited: root.ctx.buffer = text
                onAccepted: root.ctx.submit()
                Keys.onEscapePressed: root.ctx.buffer = ""
                Component.onCompleted: forceActiveFocus()
            }

            // animated dots
            Row {
                anchors.centerIn: parent
                spacing: 8
                visible: root.ctx.buffer.length > 0
                Repeater {
                    model: Math.min(root.ctx.buffer.length, 24)
                    Rectangle {
                        width: 10; height: 10; radius: 5
                        color: Theme.text
                        scale: 0
                        Component.onCompleted: scale = 1
                        Behavior on scale { Anim { duration: Theme.durMed; easing.bezierCurve: Theme.curves.springFast } }
                    }
                }
            }

            FText {
                anchors.centerIn: parent
                visible: root.ctx.buffer.length === 0
                text: root.ctx.authenticating ? "Checking…" : root.ctx.errorText || "Enter password"
                dim: !root.ctx.errorText
                color: root.ctx.errorText ? Theme.error : Theme.textDim
            }

            FIcon {
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                icon: root.ctx.authenticating ? "progress_activity" : "arrow_forward"
                color: Theme.accent
                RotationAnimation on rotation {
                    running: root.ctx.authenticating
                    from: 0; to: 360; duration: 800; loops: Animation.Infinite
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: input.forceActiveFocus()
            }
        }

        // fingerprint hint, while the reader is waiting
        Row {
            Layout.alignment: Qt.AlignHCenter
            visible: root.ctx.fpWanted
            spacing: 8
            FIcon {
                anchors.verticalCenter: parent.verticalCenter
                icon: "fingerprint"
                size: 20
                color: root.ctx.fpError ? Theme.error : Theme.accent
            }
            FText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.ctx.fpText || "Or touch the fingerprint reader"
                color: root.ctx.fpError ? Theme.error : Theme.textDim
                font.pixelSize: Theme.fsSm
            }
        }
    }

    // media + session
    RowLayout {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 40 - (1 - root.p) * 100
        opacity: root.p
        spacing: Theme.sp3

        Rectangle {
            visible: Media.active && Settings.data.lock.showMedia
            implicitWidth: mrow.implicitWidth + 24
            implicitHeight: 52
            radius: 26
            color: Theme.alpha(Theme.surface, 0.75)
            RowLayout {
                id: mrow
                anchors.centerIn: parent
                spacing: 8
                FIcon { icon: "music_note"; color: Theme.accent }
                FText { text: Media.title; Layout.maximumWidth: 260; elide: Text.ElideRight }
                FIconButton { icon: "skip_previous"; size: 32; onClicked: Media.previous() }
                FIconButton { icon: Media.playing ? "pause" : "play_arrow"; size: 36; active: true; onClicked: Media.toggle() }
                FIconButton { icon: "skip_next"; size: 32; onClicked: Media.next() }
            }
        }

        FIconButton { icon: "bedtime"; size: 52; flat: false; onClicked: Power.suspend() }
        FIconButton { icon: "restart_alt"; size: 52; flat: false; onClicked: Power.reboot() }
        FIconButton { icon: "power_settings_new"; size: 52; flat: false; iconColor: Theme.error; onClicked: Power.shutdown() }
    }

    // battery
    Row {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 24
        spacing: 6
        visible: Power.hasBattery
        opacity: root.p
        FIcon { icon: Power.icon; rotation: 90; fill: 1 }
        FText { text: Power.percent + "%" }
    }
}
