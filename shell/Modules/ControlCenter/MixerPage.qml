import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets
import qs.Modules.Volume

// Control center → Mixer: each app's volume, mute and output, and apps recording.
DetailPage {
    id: page
    title: "Mixer"
    headerExtra: FIconButton {
        icon: "tune"
        size: 30
        onClicked: Panels.openSettings("sound")
    }

    AppMixer {
        Layout.fillWidth: true
    }
}
