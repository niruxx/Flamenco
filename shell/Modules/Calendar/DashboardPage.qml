import QtQuick
import qs.Commons
import qs.Widgets

// One dashboard tab page; slides and fades when it becomes (in)active.
// Its content (`page`) is only made the first time it's shown while the
// dashboard is open, in the background, and let go when the dashboard closes:
// hidden pages cost nothing.
Item {
    id: root
    property int index
    property int currentIndex
    property bool open: true                   // the dashboard is showing
    property Component page
    readonly property bool active: currentIndex === index && index >= 0
    readonly property Item item: loader.item
    // shown once since the dashboard opened: kept until it closes
    property bool kept: false
    onActiveChanged: if (active && open) kept = true
    onOpenChanged: kept = open && active

    implicitHeight: loader.item ? loader.item.implicitHeight : 0
    visible: opacity > 0.01
    opacity: active && loader.status === Loader.Ready ? 1 : 0
    x: active ? 0 : (index < currentIndex ? -40 : 40)

    Behavior on opacity { Anim { duration: Theme.durMed } }
    Behavior on x { Anim { duration: Theme.durLong; easing.bezierCurve: Theme.curves.emphasizedDecel } }

    Loader {
        id: loader
        width: root.width
        active: root.kept || (root.active && root.open)
        asynchronous: true
        sourceComponent: root.page
    }
}
