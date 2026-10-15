import QtQuick
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

// The panel Noctalia and DMS plugins open: a Noctalia plugin's Panel.qml (with its
// pluginApi), or a DMS bar widget's popout. One at a time (ThirdParty.panelKey).
Variants {
    model: Quickshell.screens

    OverlayPanel {
        id: panel
        name: "thirdparty"
        exclusiveKeyboard: true

        readonly property var plugin: ThirdParty.find(ThirdParty.panelKey)
        readonly property bool isDms: ThirdParty.popoutOwner !== null
        property var content: null
        property bool failed: false
        // the size the plugin asks for (Noctalia: contentPreferredWidth/Height, DMS: popoutWidth/Height)
        readonly property real wantW: isDms ? (ThirdParty.popoutOwner?.popoutWidth ?? 400) : (content?.contentPreferredWidth ?? 440)
        readonly property real wantH: isDms ? ((ThirdParty.popoutOwner?.popoutHeight ?? 0) > 0 ? ThirdParty.popoutOwner.popoutHeight : (content?.implicitHeight ?? 300))
            : (content?.contentPreferredHeight ?? content?.implicitHeight ?? 400)
        cardWidth: Math.round(Math.max(240, wantW) + cardPadding * 2)

        function build() {
            if (content) {
                content.destroy();
                content = null;
            }
            failed = false;
            if (isDms) {
                const comp = ThirdParty.popoutOwner?.popoutContent;
                if (!comp)
                    return;
                const obj = comp.createObject(host, {});
                if (!obj) {
                    failed = true;
                    ThirdParty.fail(ThirdParty.panelKey, "popout", comp.errorString ? comp.errorString() : "couldn't create it");
                    return;
                }
                if (obj.closePopout !== undefined)
                    obj.closePopout = () => ThirdParty.closePanel();
                if (obj.parentPopout !== undefined)
                    obj.parentPopout = panel;
                content = obj;
                return;
            }
            const file = plugin?.entries?.panel;
            if (!file)
                return;
            const comp = Qt.createComponent("file://" + file);
            const make = () => {
                if (comp.status === Component.Error) {
                    failed = true;
                    ThirdParty.fail(ThirdParty.panelKey, "panel", comp.errorString());
                    return;
                }
                const obj = comp.createObject(host, { pluginApi: ThirdParty.noctaliaApi(ThirdParty.panelKey) });
                if (!obj) {
                    failed = true;
                    ThirdParty.fail(ThirdParty.panelKey, "panel", "couldn't create it");
                    return;
                }
                content = obj;
            };
            if (comp.status === Component.Loading)
                comp.statusChanged.connect(make);
            else
                make();
        }

        // another plugin's panel asked for while this one is open
        Connections {
            target: ThirdParty
            function onPanelKeyChanged() {
                if (panel.shouldShow)
                    panel.build();
            }
            function onPopoutOwnerChanged() {
                if (panel.shouldShow)
                    panel.build();
            }
        }

        // made when it opens, and gone when it has closed (plugins expect a fresh one)
        onOpened: build()
        onShouldShowChanged: if (!shouldShow) teardown.restart()
        Timer {
            id: teardown
            interval: 600
            onTriggered: if (!panel.shouldShow && panel.content) {
                panel.content.destroy();
                panel.content = null;
            }
        }

        Item {
            id: host
            width: panel.cardWidth - panel.cardPadding * 2
            implicitHeight: panel.failed ? 80 : Math.min(panel.wantH, (panel.modelData.height || 900) * 0.85)
            height: implicitHeight
            clip: true

            // Noctalia panels fill their host; DMS popouts take its width
            Binding {
                when: panel.content !== null && !panel.isDms
                target: panel.content
                property: "anchors.fill"
                value: host
            }
            Binding {
                when: panel.content !== null && panel.isDms
                target: panel.content
                property: "width"
                value: host.width
            }

            FText {
                anchors.centerIn: parent
                visible: panel.failed
                width: parent.width - 20
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: (panel.plugin?.name ?? "This plugin") + "'s panel didn't load. Settings → Plugins (3rd party) says why."
                dim: true
            }
        }
    }
}
