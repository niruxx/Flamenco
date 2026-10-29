import QtQuick
import qs.Commons
import qs.Widgets

// One dashboard tab page; slides and fades when it becomes (in)active.
// Its content (`page`) is only made the first time it's shown while the
// dashboard is open, in the background, and let go when the dashboard closes:
// hidden pages cost nothing.
//
// The background build can stall (it advances on the window's frames, and the
// loader thread can jam), which left a page, most often the heavy Wallpaper one,
// invisible until a restart. So if a page you picked isn't ready soon, it's
// finished directly instead, and a page that failed to build is tried again once.
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
    onOpenChanged: {
        kept = open && active;
        if (!open)
            retried = false;
    }

    implicitHeight: loader.item ? loader.item.implicitHeight : 0
    visible: opacity > 0.01
    enabled: active && loader.status === Loader.Ready
    opacity: active && loader.status === Loader.Ready ? 1 : 0
    x: active || !Theme.pageSlide ? 0 : Theme.travel(index < currentIndex ? -24 : 24, "calendar") * Theme.scale

    Behavior on opacity { Anim { area: "calendar"; duration: Theme.pageDuration(area) } }
    Behavior on x { Anim { area: "calendar"; duration: Theme.pageDuration(area); easing.bezierCurve: Theme.curves.emphasizedDecel } }

    Loader {
        id: loader
        width: root.width
        active: root.kept || (root.active && root.open)
        asynchronous: true
        sourceComponent: root.page
        onStatusChanged: {
            if (status === Loader.Ready || status === Loader.Null) {
                watchdog.stop();
                if (status === Loader.Null)
                    asynchronous = true;      // the next opening builds in the background again
            } else if (status === Loader.Error) {
                console.warn("[DashboardPage] page", root.index, "failed to load; retrying");
                retry.restart();
            }
        }
    }

    // shown but still building: finish it now (turning `asynchronous` off completes the build)
    readonly property bool waiting: active && open && loader.status === Loader.Loading
    onWaitingChanged: waiting ? watchdog.restart() : watchdog.stop()
    Timer {
        id: watchdog
        interval: 700
        onTriggered: if (root.waiting) loader.asynchronous = false
    }
    property bool retried: false              // reset when the dashboard closes (onOpenChanged above)
    Timer {
        id: retry
        interval: 50
        onTriggered: {
            if (root.retried)
                return;
            root.retried = true;
            loader.asynchronous = false;
            loader.sourceComponent = null;
            loader.sourceComponent = Qt.binding(() => root.page);
        }
    }
}
