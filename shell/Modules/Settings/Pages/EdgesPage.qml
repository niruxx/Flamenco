import QtQuick
import qs.Services as S
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: I18n.tr("Screen edges")
    subtitle: I18n.tr("Push the pointer into a corner of the screen to run an action.")
    readonly property var e: Settings.data.edges
    readonly property var actions: S.Edges.actions.filter(a => !(Niri.hyprland && a.niriOnly)).map(a => ({ value: a.value, label: a.label }))

    // niri's own hot corners are written from here, through the compositor config
    Component.onCompleted: Compositor.load()

    function changed() {
        if (!Niri.hyprland)
            Compositor.queue();
    }

    Group {
        title: I18n.tr("Hot corners")
        SwitchRow { title: I18n.tr("Use hot corners"); subtitle: Niri.hyprland ? "" : I18n.tr("Also turns niri's own hot corner on or off"); icon: "select_all"; target: page.e; key: "enabled"; onEdited: page.changed() }
        DropdownRow { title: I18n.tr("Top left"); icon: "north_west"; visible: page.e.enabled; target: page.e; key: "topLeft"; options: page.actions; onEdited: page.changed() }
        DropdownRow { title: I18n.tr("Top right"); icon: "north_east"; visible: page.e.enabled; target: page.e; key: "topRight"; options: page.actions; onEdited: page.changed() }
        DropdownRow { title: I18n.tr("Bottom left"); icon: "south_west"; visible: page.e.enabled; target: page.e; key: "bottomLeft"; options: page.actions; onEdited: page.changed() }
        DropdownRow { title: I18n.tr("Bottom right"); icon: "south_east"; visible: page.e.enabled; target: page.e; key: "bottomRight"; options: page.actions; onEdited: page.changed() }
    }

    Group {
        title: I18n.tr("Feel")
        visible: page.e.enabled
        SliderRow { title: I18n.tr("Delay"); subtitle: I18n.tr("How long the pointer has to rest in the corner") + (Niri.hyprland ? "" : ". Overview corners are niri's own and react at once."); icon: "timer"; target: page.e; key: "delay"; from: 0; to: 1000; stepSize: 50; suffix: " ms" }
        SliderRow { title: I18n.tr("Corner size"); subtitle: I18n.tr("The area that reacts, in pixels"); icon: "crop_free"; target: page.e; key: "size"; from: 1; to: 12; stepSize: 1; suffix: " px" }
    }

    FText {
        Layout.fillWidth: true
        visible: !Niri.hyprland && page.e.enabled
        text: I18n.tr("Corners set to Overview are niri's own hot corners, so they also work while you drag a window. niri's corner is turned off everywhere else, so it doesn't get in the way of these actions.")
            + (S.Edges.perCorner ? "" : " This niri only has its own top-left corner; other Overview corners are done by Flamenco.")
        dim: true
        wrapMode: Text.Wrap
    }

    FText {
        Layout.fillWidth: true
        visible: !Niri.hyprland && Compositor.status !== ""
        text: Compositor.status
        dim: !Compositor.failed
        color: Compositor.failed ? Theme.error : Theme.textDim
        wrapMode: Text.Wrap
    }
}
