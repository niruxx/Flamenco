pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// The AI assistant: providers and their status (`flamenco ai providers`), the
// conversation in the Assistant panel, and streaming replies (`flamenco ai chat`,
// which gets the conversation on stdin and answers with JSON lines).
Singleton {
    id: root

    readonly property var cfg: Settings.data.ai
    property var status: ({ providers: [], keyring: false, anthropicSdk: false })
    readonly property var providers: status.providers ?? []
    readonly property var current: providers.find(p => p.id === cfg.provider) ?? null
    readonly property string model: current ? (current.model || "") : ""
    readonly property bool ready: !!current && model !== "" && (current.key !== "required" || current.keyFrom !== "")
        && (current.kind !== "anthropic" || status.anthropicSdk)

    // the conversation: { role: user | assistant, content, error }
    property ListModel messages: ListModel {}
    property bool busy: false
    property string error: ""

    // models per provider, as last listed: { id: { list: [...], error } }
    property var models: ({})
    property var tests: ({})            // { id: { running, ok, text } }

    function refresh() {
        if (!lister.running)
            lister.running = true;
    }

    function setProvider(id, changes) {
        const all = Object.assign({}, cfg.providers || {});
        all[id] = Object.assign({}, all[id] || {}, changes);
        cfg.providers = all;
        refreshSoon.restart();
    }

    function listModels(id) {
        const m = Object.assign({}, models);
        m[id] = { list: (models[id]?.list ?? []), error: "", loading: true };
        models = m;
        const proc = modelProc.createObject(root, { pid: id });
        proc.running = true;
    }

    function test(id) {
        const t = Object.assign({}, tests);
        t[id] = { running: true, ok: false, text: "" };
        tests = t;
        const proc = testProc.createObject(root, { pid: id });
        proc.running = true;
    }

    function saveKey(id, key) {
        const proc = keyProc.createObject(root, { pid: id, key: key, remove: false });
        proc.running = true;
    }

    function deleteKey(id) {
        const proc = keyProc.createObject(root, { pid: id, key: "", remove: true });
        proc.running = true;
    }

    function send(text) {
        text = String(text).trim();
        if (text === "" || busy)
            return;
        error = "";
        messages.append({ role: "user", content: text, error: false });
        const history = [];
        for (let i = 0; i < messages.count; i++) {
            const m = messages.get(i);
            if (!m.error && m.content !== "")
                history.push({ role: m.role, content: m.content });
        }
        messages.append({ role: "assistant", content: "", error: false });
        chat.request = JSON.stringify({ provider: cfg.provider, model: model, system: cfg.systemPrompt, effort: cfg.effort, messages: history });
        busy = true;
        chat.running = true;
    }

    function stop() {
        chat.running = false;
    }

    function clear() {
        stop();
        messages.clear();
        error = "";
    }

    Component.onCompleted: refresh()

    Timer {
        id: refreshSoon
        interval: 500
        onTriggered: root.refresh()
    }

    Process {
        id: lister
        command: [Paths.bin, "ai", "providers"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.status = JSON.parse(text);
                } catch (e) {}
            }
        }
    }

    Process {
        id: chat
        property string request: ""
        command: [Paths.bin, "ai", "chat"]
        stdinEnabled: true
        onStarted: write(request + "\n")
        stdout: SplitParser {
            onRead: line => {
                let ev;
                try {
                    ev = JSON.parse(line);
                } catch (e) {
                    return;
                }
                const last = root.messages.count - 1;
                if (ev.t === "delta" && last >= 0)
                    root.messages.setProperty(last, "content", root.messages.get(last).content + ev.text);
                else if (ev.t === "error")
                    root.error = ev.message;
            }
        }
        onExited: {
            root.busy = false;
            // an empty or failed reply isn't sent back next time
            const last = root.messages.count - 1;
            if (last >= 0 && root.messages.get(last).role === "assistant" && root.messages.get(last).content === "")
                root.messages.setProperty(last, "error", true);
        }
    }

    Component {
        id: modelProc
        Process {
            id: mp
            property string pid
            command: [Paths.bin, "ai", "models", pid]
            stdout: StdioCollector {
                onStreamFinished: {
                    let d = { models: [], error: "no answer" };
                    try {
                        d = JSON.parse(text);
                    } catch (e) {}
                    const m = Object.assign({}, root.models);
                    m[mp.pid] = { list: d.models ?? [], error: d.error ?? "", loading: false };
                    root.models = m;
                    mp.destroy();
                }
            }
        }
    }

    Component {
        id: testProc
        Process {
            id: tp
            property string pid
            property string reply: ""
            property string err: ""
            command: [Paths.bin, "ai", "test", pid]
            stdout: SplitParser {
                onRead: line => {
                    try {
                        const ev = JSON.parse(line);
                        if (ev.t === "delta")
                            tp.reply += ev.text;
                        else if (ev.t === "error")
                            tp.err = ev.message;
                    } catch (e) {}
                }
            }
            onExited: code => {
                const t = Object.assign({}, root.tests);
                t[tp.pid] = { running: false, ok: code === 0 && tp.err === "", text: tp.err || ("Connected. The model replied: " + tp.reply.trim().slice(0, 80)) };
                root.tests = t;
                tp.destroy();
            }
        }
    }

    Component {
        id: keyProc
        Process {
            id: kp
            property string pid
            property string key
            property bool remove
            command: [Paths.bin, "ai", "key", remove ? "delete" : "set", pid]
            stdinEnabled: !remove
            onStarted: if (!remove) write(key + "\n")
            onExited: {
                root.refresh();
                kp.destroy();
            }
        }
    }
}
