import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: I18n.tr("Mouse & Touchpad")
    subtitle: I18n.tr("Pointer speed, acceleration, scrolling and tapping. Saved into the compositor config, so it applies everywhere right away.")
    readonly property var pc: Settings.data.pointer
    readonly property var accel: [{ value: "adaptive", label: I18n.tr("Adaptive") }, { value: "flat", label: I18n.tr("Flat") }]

    Component.onCompleted: Pointer.load()

    Group {
        title: I18n.tr("Mouse")
        SliderRow { title: I18n.tr("Pointer speed"); subtitle: I18n.tr("0% is the default; negative is slower"); icon: "speed"; target: page.pc; key: "mouseSpeed"; from: -1; to: 1; stepSize: 0.05; factor: 100; suffix: "%"; onEdited: Pointer.queue() }
        ChoiceRow { title: I18n.tr("Acceleration"); subtitle: I18n.tr("Flat moves the pointer the same distance however fast you move (good for games)"); icon: "trending_up"; target: page.pc; key: "mouseAccel"; options: page.accel; onEdited: Pointer.queue() }
        SliderRow { title: I18n.tr("Scroll speed"); icon: "swap_vert"; target: page.pc; key: "mouseScroll"; from: 0.25; to: 3; stepSize: 0.05; decimals: 2; suffix: "×"; onEdited: Pointer.queue() }
        SwitchRow { title: I18n.tr("Natural scrolling"); subtitle: I18n.tr("Content follows the wheel, like on a phone"); icon: "unfold_more"; target: page.pc; key: "mouseNatural"; onEdited: Pointer.queue() }
        SwitchRow { title: I18n.tr("Left-handed"); subtitle: I18n.tr("Swap the left and right buttons"); icon: "back_hand"; target: page.pc; key: "mouseLeftHanded"; onEdited: Pointer.queue() }
    }

    Group {
        title: I18n.tr("Touchpad")
        SliderRow { title: I18n.tr("Pointer speed"); subtitle: Niri.hyprland ? I18n.tr("Hyprland uses the mouse speed for touchpads too") : "0% is the default; negative is slower"; icon: "speed"; target: page.pc; key: "touchSpeed"; from: -1; to: 1; stepSize: 0.05; factor: 100; suffix: "%"; onEdited: Pointer.queue() }
        ChoiceRow { title: I18n.tr("Acceleration"); icon: "trending_up"; target: page.pc; key: "touchAccel"; options: page.accel; onEdited: Pointer.queue() }
        SliderRow { title: I18n.tr("Scroll speed"); icon: "swap_vert"; target: page.pc; key: "touchScroll"; from: 0.25; to: 3; stepSize: 0.05; decimals: 2; suffix: "×"; onEdited: Pointer.queue() }
        SwitchRow { title: I18n.tr("Natural scrolling"); icon: "unfold_more"; target: page.pc; key: "touchNatural"; onEdited: Pointer.queue() }
        SwitchRow { title: I18n.tr("Tap to click"); icon: "touch_app"; target: page.pc; key: "tap"; onEdited: Pointer.queue() }
        SwitchRow { title: I18n.tr("Disable while typing"); subtitle: I18n.tr("Ignore the touchpad for a moment after a key press"); icon: "keyboard_hide"; target: page.pc; key: "dwt"; onEdited: Pointer.queue() }
        SwitchRow { title: I18n.tr("Off when a mouse is plugged in"); icon: "mouse"; visible: !Niri.hyprland; target: page.pc; key: "disableWithMouse"; onEdited: Pointer.queue() }
    }

    FText {
        visible: Pointer.status !== ""
        text: Pointer.status
        dim: true
    }
}
