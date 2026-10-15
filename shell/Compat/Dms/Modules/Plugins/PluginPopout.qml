import QtQuick

// Flamenco's version of DMS's PluginPopout: DMS popouts open in Flamenco's panel
// for 3rd-party plugins, so this only keeps the properties plugins may set.
Item {
    property var triggerScreen: null
    property Component pluginContent: null
    property real contentWidth: 400
    property real contentHeight: 0
    property bool shouldBeVisible: false
    function open() {}
    function close() {}
    function toggle() {}
    function setTriggerPosition(x, y, width, section, screen) {}
}
