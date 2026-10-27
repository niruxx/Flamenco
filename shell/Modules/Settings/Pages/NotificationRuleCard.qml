import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// One notification rule (Settings → Notifications → App rules): an app (and
// optionally words in the text), and what its notifications do. Folded to a summary
// line; click to edit.
Rectangle {
    id: root
    required property var rule
    required property int index
    property bool open: false
    readonly property var r: rule
    readonly property string summary: {
        const s = [];
        if (r.popup === "never") s.push("no pop-ups");
        if (r.popup === "always") s.push("pop up even in Do Not Disturb");
        if (r.sound === false) s.push("silent");
        if (r.urgency && r.urgency !== "default") s.push(r.urgency + " urgency");
        if (r.timeout > 0) s.push(r.timeout + " s");
        if (r.timeout < 0) s.push("stays until dismissed");
        if (r.history === false) s.push("not kept in history");
        return s.length ? s.join(" · ") : "As usual (nothing changed yet)";
    }

    function set(k, v) {
        const all = (Settings.data.notifications.rules || []).slice();
        all[index] = Object.assign({}, all[index], { [k]: v });
        Settings.data.notifications.rules = all;
    }
    function remove() {
        Settings.data.notifications.rules = (Settings.data.notifications.rules || []).filter((x, i) => i !== index);
    }

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + Theme.sp3 * 2
    radius: Theme.rLg
    color: Theme.alpha(Theme.text, open ? 0.06 : 0.035)
    border.width: open ? 1 : 0
    border.color: Theme.alpha(Theme.accent, 0.4)

    ColumnLayout {
        id: col
        x: Theme.sp3
        y: Theme.sp3
        width: parent.width - Theme.sp3 * 2
        spacing: Theme.sp2

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.sp3
            AppIcon {
                implicitSize: 30
                name: Apps.iconFor(root.r.app || "") || "dialog-information"
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                FText {
                    Layout.fillWidth: true
                    text: (root.r.app || "Pick an app") + (root.r.contains ? " · text has “" + root.r.contains + "”" : "")
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                FText {
                    Layout.fillWidth: true
                    text: root.summary
                    dim: true
                    font.pixelSize: Theme.fsSm
                    elide: Text.ElideRight
                }
            }
            FIconButton { icon: root.open ? "expand_less" : "edit"; size: 30; onClicked: root.open = !root.open }
            FIconButton { icon: "delete"; size: 30; iconColor: Theme.error; onClicked: root.remove() }
        }

        GridLayout {
            visible: root.open
            Layout.fillWidth: true
            Layout.topMargin: Theme.sp2
            columns: 2
            columnSpacing: Theme.sp3
            rowSpacing: Theme.sp2

            FText { text: "App"; dim: true }
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.sp2
                FTextField {
                    Layout.fillWidth: true
                    implicitHeight: 36
                    text: root.r.app || ""
                    placeholder: "The name it sends, e.g. Discord"
                    onEditingFinished: if (text.trim() !== (root.r.app || "")) root.set("app", text.trim())
                }
                FDropdown {
                    implicitWidth: 170
                    implicitHeight: 36
                    placeholder: "From history"
                    options: Notifs.apps
                    onSelected: v => root.set("app", v)
                }
            }
            FText { text: "Text has"; dim: true }
            FTextField {
                Layout.fillWidth: true
                implicitHeight: 36
                text: root.r.contains || ""
                placeholder: "Optional: only notifications with these words"
                onEditingFinished: if (text.trim() !== (root.r.contains || "")) root.set("contains", text.trim())
            }
            FText { text: "Pop-ups"; dim: true }
            FSegmented {
                implicitWidth: 330
                implicitHeight: 34
                options: [{ value: "default", label: "As usual" }, { value: "never", label: "Never" }, { value: "always", label: "Even in DND" }]
                current: root.r.popup || "default"
                onSelected: v => root.set("popup", v)
            }
            FText { text: "Urgency"; dim: true }
            FSegmented {
                implicitWidth: 330
                implicitHeight: 34
                options: [{ value: "default", label: "As sent" }, { value: "low", label: "Low" }, { value: "normal", label: "Normal" }, { value: "critical", label: "Critical" }]
                current: root.r.urgency || "default"
                onSelected: v => root.set("urgency", v)
            }
            FText { text: "Stays"; dim: true }
            FDropdown {
                implicitWidth: 220
                implicitHeight: 36
                options: [{ value: 0, label: "As usual" }, { value: 3, label: "3 seconds" }, { value: 5, label: "5 seconds" }, { value: 10, label: "10 seconds" },
                    { value: 20, label: "20 seconds" }, { value: 60, label: "A minute" }, { value: -1, label: "Until dismissed" }]
                current: root.r.timeout || 0
                onSelected: v => root.set("timeout", v)
            }
            FText { text: "Also"; dim: true }
            Flow {
                Layout.fillWidth: true
                spacing: Theme.sp3
                Repeater {
                    model: [{ k: "sound", t: "Sound" }, { k: "history", t: "Keep in history" }]
                    Row {
                        required property var modelData
                        spacing: 6
                        FSwitch {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: root.r[parent.modelData.k] !== false
                            onToggled: c => root.set(parent.modelData.k, c)
                        }
                        FText { anchors.verticalCenter: parent.verticalCenter; text: parent.modelData.t }
                    }
                }
            }
        }
    }
}
