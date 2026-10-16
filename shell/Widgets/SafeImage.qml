import QtQuick

// An image that loads in the background, and loads directly instead if the
// background loader hasn't delivered it after a few seconds (if that shared
// thread ever jams, pictures still show up rather than staying blank until a
// restart). Set `path`, not `source`.
Image {
    id: root

    property url path
    property int patience: 4000

    asynchronous: true
    source: path

    onPathChanged: {
        if (!asynchronous)
            asynchronous = true;          // a new picture gets the background loader again
        if (String(path) !== "")
            stuck.restart();
    }
    onStatusChanged: if (status !== Image.Loading) stuck.stop()

    Timer {
        id: stuck
        interval: root.patience
        onTriggered: {
            if (root.status !== Image.Loading || String(root.path) === "")
                return;
            root.asynchronous = false;
            // load it again, directly this time
            root.source = "";
            root.source = Qt.binding(() => root.path);
        }
    }
}
