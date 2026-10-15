// Vendored from https://github.com/AvengeMedia/DankMaterialShell (v1.6) and dank-qml-common (stable-1.6) (MIT) by tools/compat-vendor.py.
// Don't edit: change the vendoring tool or a Flamenco shim next to it.
import QtQuick
import Quickshell.Wayland
import qs.Compat.Dms.Common
import qs.Compat.Dms.Modals.Common

DankModal {
    id: fileBrowserSurfaceModal

    property string browserTitle: "Select File"
    property string browserIcon: "folder_open"
    property string browserType: "generic"
    property var fileExtensions: ["*.*"]
    property alias filterExtensions: fileBrowserSurfaceModal.fileExtensions
    property bool showHiddenFiles: false
    property bool saveMode: false
    property bool folderMode: false
    property string defaultFileName: ""
    property var parentPopout: null

    signal fileSelected(string path)

    layerNamespace: "dms:filebrowser"
    modalWidth: 800
    modalHeight: 600
    backgroundColor: Theme.withAlpha(Theme.surfaceContainer, Theme.popupTransparency)
    closeOnEscapeKey: true
    closeOnBackgroundClick: true
    allowStacking: true
    useOverlayLayer: true
    keepPopoutsOpen: true

    onBackgroundClicked: close()

    onOpened: {
        if (parentPopout) {
            parentPopout.customKeyboardFocus = WlrKeyboardFocus.None;
        }
        Qt.callLater(() => {
            if (contentLoader.item) {
                contentLoader.item.reset();
                contentLoader.item.forceActiveFocus();
            }
        });
    }

    onDialogClosed: {
        if (parentPopout) {
            parentPopout.customKeyboardFocus = null;
        }
    }

    content: FileBrowserContent {
        focus: true

        browserTitle: fileBrowserSurfaceModal.browserTitle
        browserIcon: fileBrowserSurfaceModal.browserIcon
        browserType: fileBrowserSurfaceModal.browserType
        fileExtensions: fileBrowserSurfaceModal.fileExtensions
        showHiddenFiles: fileBrowserSurfaceModal.showHiddenFiles
        saveMode: fileBrowserSurfaceModal.saveMode
        folderMode: fileBrowserSurfaceModal.folderMode
        defaultFileName: fileBrowserSurfaceModal.defaultFileName

        Component.onCompleted: initialize()

        onFileSelected: path => fileBrowserSurfaceModal.fileSelected(path)
        onCloseRequested: fileBrowserSurfaceModal.close()
    }
}
