import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

// AI: which provider the Assistant uses, its key, address and model.
Page {
    id: page
    title: "AI"
    subtitle: "Connect a language model for the Assistant: Claude, OpenAI, Gemini, OpenRouter, or one running on this computer in LM Studio or Ollama."
    readonly property var a: Settings.data.ai
    readonly property var p: Ai.current
    readonly property bool local: !!p && (p.id === "lmstudio" || p.id === "ollama")
    readonly property var modelInfo: p ? (Ai.models[p.id] ?? null) : null
    readonly property var testInfo: p ? (Ai.tests[p.id] ?? null) : null

    Component.onCompleted: Ai.refresh()

    Group {
        title: "Assistant"
        SwitchRow { title: "Assistant"; subtitle: "Adds an Assistant button you can put in the bar, and a shortcut (Settings → Keyboard → Flamenco functions)"; icon: "auto_awesome"; target: page.a; key: "enabled" }
        SettingRow {
            title: "Open the assistant"
            subtitle: Ai.ready ? "Ready: " + page.p.name + " · " + Ai.model : "Finish setting up a provider below first"
            icon: Ai.ready ? "check_circle" : "info"
            FButton {
                text: "Open"
                variant: "tonal"
                disabled: !Ai.ready
                onClicked: {
                    Panels.settingsOpen = false;
                    Panels.open("assistant", "");
                }
            }
        }
    }

    Group {
        title: "Provider"
        DropdownRow {
            title: "Provider"
            icon: "hub"
            target: page.a
            key: "provider"
            options: Ai.providers.map(x => ({ value: x.id, label: x.name }))
        }

        SettingRow {
            visible: !!page.p && page.p.kind === "anthropic" && !Ai.status.anthropicSdk
            title: "Needs the Anthropic SDK"
            subtitle: "Claude is reached through Anthropic's official Python SDK. Install python-anthropic (AUR), then press refresh."
            icon: "warning"
            FIconButton { icon: "refresh"; size: 32; onClicked: Ai.refresh() }
        }

        SettingRow {
            visible: page.local
            title: page.p?.id === "lmstudio" ? "Start LM Studio's server" : "Run Ollama"
            subtitle: page.p?.id === "lmstudio" ? "In LM Studio: Developer → Start Server (port 1234), with a model loaded. Nothing leaves this computer."
                : "Start it with `ollama serve` (or its systemd service) and pull a model, e.g. `ollama pull llama3.2`. Nothing leaves this computer."
            icon: "computer"
        }

        // server address (not for Claude)
        SettingRow {
            visible: !!page.p && page.p.kind === "openai"
            title: "Server address"
            subtitle: page.p && page.p.defaultBase ? "Default: " + page.p.defaultBase : "The /v1 address of an OpenAI-compatible server"
            icon: "link"
            FTextField {
                implicitWidth: 300
                text: page.p?.baseUrl ?? ""
                placeholder: "http://localhost:1234/v1"
                onEditingFinished: if (page.p && text.trim() !== page.p.baseUrl) Ai.setProvider(page.p.id, { baseUrl: text.trim() })
                onAccepted: if (page.p) Ai.setProvider(page.p.id, { baseUrl: text.trim() })
            }
        }

        // API key
        SettingRow {
            visible: !!page.p && page.p.key !== "none"
            title: "API key"
            subtitle: !page.p ? "" : page.p.keyFrom === "keyring" ? "Saved in your keyring"
                : page.p.keyFrom === "file" ? "Saved in ~/.config/flamenco/ai-keys.json (only you can read it)"
                : page.p.keyFrom === "env" ? "From $" + page.p.env
                : page.p.kind === "anthropic" ? "Not set: Claude also works with $ANTHROPIC_API_KEY or `ant auth login`"
                : page.p.key === "required" ? "Needed for " + page.p.name : "Only if your server asks for one"
            icon: "key"
            Row {
                spacing: 8
                FTextField {
                    id: keyField
                    implicitWidth: 220
                    password: true
                    placeholder: page.p?.keyFrom ? "Replace the key" : "Paste the key"
                }
                FButton {
                    text: "Save"
                    disabled: keyField.text.trim() === ""
                    onClicked: {
                        Ai.saveKey(page.p.id, keyField.text.trim());
                        keyField.text = "";
                    }
                }
                FButton {
                    visible: page.p?.keyFrom === "keyring" || page.p?.keyFrom === "file"
                    text: "Remove"
                    variant: "text"
                    onClicked: Ai.deleteKey(page.p.id)
                }
            }
        }

        // model
        SettingRow {
            visible: !!page.p
            title: "Model"
            subtitle: page.modelInfo?.loading ? "Asking " + (page.p?.name ?? "") + " for its models…"
                : page.modelInfo?.error ? page.modelInfo.error
                : page.modelInfo ? page.modelInfo.list.length + " models available. Or type one."
                : "Press refresh to list the models " + (page.p?.name ?? "") + " offers, or type one."
            icon: "neurology"
            Row {
                spacing: 8
                FDropdown {
                    implicitWidth: 240
                    visible: (page.modelInfo?.list ?? []).length > 0
                    options: {
                        const l = (page.modelInfo?.list ?? []).slice();
                        if (page.p?.model && !l.includes(page.p.model))
                            l.unshift(page.p.model);
                        return l;
                    }
                    current: page.p?.model ?? ""
                    placeholder: "Choose a model…"
                    onSelected: v => Ai.setProvider(page.p.id, { model: v })
                }
                FTextField {
                    implicitWidth: (page.modelInfo?.list ?? []).length > 0 ? 150 : 240
                    text: page.p?.model ?? ""
                    placeholder: "model id"
                    onEditingFinished: if (page.p && text.trim() !== page.p.model) Ai.setProvider(page.p.id, { model: text.trim() })
                    onAccepted: if (page.p) Ai.setProvider(page.p.id, { model: text.trim() })
                }
                FIconButton {
                    icon: "refresh"
                    size: 32
                    onClicked: Ai.listModels(page.p.id)
                }
            }
        }

        SettingRow {
            visible: !!page.p
            title: "Test the connection"
            subtitle: page.testInfo ? (page.testInfo.running ? "Asking the model to say ok…" : page.testInfo.text) : "Sends one short message"
            icon: page.testInfo && !page.testInfo.running ? (page.testInfo.ok ? "check_circle" : "error") : "network_check"
            FButton {
                text: "Test"
                variant: "tonal"
                disabled: !!page.testInfo?.running || !(page.p?.model)
                onClicked: Ai.test(page.p.id)
            }
        }
    }

    Group {
        title: "Behavior"
        TextRow {
            title: "Instructions"
            subtitle: "Sent before every conversation (the system prompt)"
            icon: "description"
            target: page.a
            key: "systemPrompt"
        }
        ChoiceRow {
            visible: page.p?.kind === "anthropic"
            title: "How hard Claude thinks"
            subtitle: "Higher is more thorough, but slower and uses more tokens"
            icon: "psychology"
            target: page.a
            key: "effort"
            options: [{ value: "low", label: "Quick" }, { value: "medium", label: "Balanced" }, { value: "high", label: "Thorough" }]
        }
        SettingRow {
            title: "Privacy"
            subtitle: page.local ? "Conversations stay on this computer." : "What you type in the Assistant is sent to " + (page.p?.name ?? "the provider") + ". Conversations aren't saved by Flamenco; they're gone when you clear them or restart the shell."
            icon: "shield"
        }
    }
}
