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

    // niri's own hot corners are written from here, through the compositor config
    Component.onCompleted: Compositor.load()

    function changed() {
        if (!Niri.hyprland)
            Compositor.queue();
    }

    Group {
        title: "Hot corners"
        SwitchRow { title: "Use hot corners"; subtitle: Niri.hyprland ? "" : "Also turns niri's own hot corner on or off"; icon: "select_all"; target: page.e; key: "enabled"; onEdited: page.changed() }
        DropdownRow { title: "Top left"; icon: "north_west"; visible: page.e.enabled; target: page.e; key: "topLeft"; options: page.actions; onEdited: page.changed() }
        DropdownRow { title: "Top right"; icon: "north_east"; visible: page.e.enabled; target: page.e; key: "topRight"; options: page.actions; onEdited: page.changed() }
        DropdownRow { title: "Bottom left"; icon: "south_west"; visible: page.e.enabled; target: page.e; key: "bottomLeft"; options: page.actions; onEdited: page.changed() }
        DropdownRow { title: "Bottom right"; icon: "south_east"; visible: page.e.enabled; target: page.e; key: "bottomRight"; options: page.actions; onEdited: page.changed() }
    }

    Group {
        title: "Feel"
        visible: page.e.enabled
        SliderRow { title: "Delay"; subtitle: "How long the pointer has to rest in the corner" + (Niri.hyprland ? "" : ". Overview corners are niri's own and react at once."); icon: "timer"; target: page.e; key: "delay"; from: 0; to: 1000; stepSize: 50; suffix: " ms" }
        SliderRow { title: "Corner size"; subtitle: "The area that reacts, in pixels"; icon: "crop_free"; target: page.e; key: "size"; from: 1; to: 12; stepSize: 1; suffix: " px" }
    }

    FText {
        Layout.fillWidth: true
        visible: !Niri.hyprland && page.e.enabled
        text: "Corners set to Overview are niri's own hot corners, so they also work while you drag a window. niri's corner is turned off everywhere else, so it doesn't get in the way of these actions."
            + (Edges.perCorner ? "" : " This niri only has its own top-left corner; other Overview corners are done by Flamenco.")
        dim: true
        wrapMode: Text.Wrap
    }
}
