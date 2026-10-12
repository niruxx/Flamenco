import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Page {
    id: page
    title: "Launcher"
    subtitle: "Type  =  for the calculator,  >  to run a command,  ;  to search clipboard history."
    readonly property var l: Settings.data.launcher

    Group {
        SliderRow { title: "Visible results"; icon: "format_list_numbered"; target: page.l; key: "maxResults"; from: 4; to: 14; stepSize: 1 }
        SwitchRow { title: "Calculator"; icon: "calculate"; target: page.l; key: "calculator" }
        SwitchRow { title: "Clipboard history"; subtitle: "Requires cliphist and wl-clipboard"; icon: "content_paste"; target: page.l; key: "clipboard" }
        TextRow { title: "Terminal"; subtitle: "Used for terminal apps and > commands"; icon: "terminal"; target: Settings.data.general; key: "terminal"; placeholder: "kitty" }
    }
}
