import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: "Screen edges"
    subtitle: "Push the pointer into a corner of the screen to run an action."
    readonly property var e: Settings.data.edges
    readonly property var actions: Edges.actions.filter(a => !(Niri.hyprland && a.niriOnly)).map(a => ({ value: a.value, label: a.label }))

    Group {
        title: "Hot corners"
        SwitchRow { title: "Use hot corners"; icon: "select_all"; target: page.e; key: "enabled" }
        DropdownRow { title: "Top left"; icon: "north_west"; visible: page.e.enabled; target: page.e; key: "topLeft"; options: page.actions }
        DropdownRow { title: "Top right"; icon: "north_east"; visible: page.e.enabled; target: page.e; key: "topRight"; options: page.actions }
        DropdownRow { title: "Bottom left"; icon: "south_west"; visible: page.e.enabled; target: page.e; key: "bottomLeft"; options: page.actions }
        DropdownRow { title: "Bottom right"; icon: "south_east"; visible: page.e.enabled; target: page.e; key: "bottomRight"; options: page.actions }
    }

    Group {
        title: "Feel"
        visible: page.e.enabled
        SliderRow { title: "Delay"; subtitle: "How long the pointer has to rest in the corner"; icon: "timer"; target: page.e; key: "delay"; from: 0; to: 1000; stepSize: 50; suffix: " ms" }
        SliderRow { title: "Corner size"; subtitle: "The area that reacts, in pixels"; icon: "crop_free"; target: page.e; key: "size"; from: 1; to: 12; stepSize: 1; suffix: " px" }
    }

    FText {
        Layout.fillWidth: true
        visible: !Niri.hyprland && page.e.enabled && page.e.topLeft !== "none" && Settings.data.windows.hotCorners
        text: "niri's own top-left hot corner is also on. Turn it off under Windows & Layout so it doesn't open the overview as well."
        dim: true
        wrapMode: Text.Wrap
    }
}
