import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

DetailPage {
    id: page
    property bool input: false
    title: input ? I18n.tr("Input device") : I18n.tr("Output device")

    Repeater {
        model: page.input ? Audio.sources : Audio.sinks

        ListRow {
            required property var modelData
            readonly property bool isDefault: modelData === (page.input ? Audio.source : Audio.sink)
            icon: page.input ? "mic" : modelData.name.includes("bluez") ? "headphones" : modelData.name.includes("hdmi") ? "tv" : "speaker"
            title: Audio.nodeName(modelData)
            selected: isDefault
            onClicked: page.input ? Audio.setDefaultSource(modelData) : Audio.setDefaultSink(modelData)
        }
    }
}
