import QtQuick
import qs.Commons
import qs.Widgets

// One dashboard tab page; slides and fades when it becomes (in)active.
Item {
    id: root
    property int index
    property int currentIndex
    default property alias content: holder.data
    readonly property bool active: currentIndex === index

    implicitHeight: holder.children.length ? holder.children[0].implicitHeight : 0
    visible: opacity > 0.01
    opacity: active ? 1 : 0
    x: active ? 0 : (index < currentIndex ? -40 : 40)

    Behavior on opacity { Anim { duration: Theme.durMed } }
    Behavior on x { Anim { duration: Theme.durLong; easing.bezierCurve: Theme.curves.emphasizedDecel } }

    Item {
        id: holder
        width: root.width
    }
}
