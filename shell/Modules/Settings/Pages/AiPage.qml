import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

// AI: which provider the Assistant uses, its key, address and model.
Page {
    id: page
    title: I18n.tr("AI")
    subtitle: I18n.tr("Connect a language model for the Assistant: Claude, OpenAI, Gemini, OpenRouter, or one running on this computer in LM Studio or Ollama.")
    readonly property var a: Settings.data.ai
    readonly property var p: Ai.current
    readonly property bool local: !!p && (p.id === "lmstudio" || p.id === "ollama")
    readonly property var modelInfo: p ? (Ai.models[p.id] ?? null) : null
    readonly property var testInfo: p ? (Ai.tests[p.id] ?? null) : null

    Component.onCompleted: Ai.refresh()

    Group {
        title: I18n.tr("Assistant")
        SwitchRow { title: I18n.tr("Assistant"); subtitle: I18n.tr("Adds an Assistant button you can put in the bar, and a shortcut (Settings → Keyboard → Flamenco functions)"); icon: "auto_awesome"; target: page.a; key: "enabled" }
        SettingRow {
            title: I18n.tr("Open the assistant")
            subtitle: Ai.ready ? I18n.tr("Ready: ") + page.p.name + " · " + Ai.model : I18n.tr("Finish setting up a provider below first")
            icon: Ai.ready ? "check_circle" : "info"
            FButton {
                text: I18n.tr("Open")
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
        title: I18n.tr("Provider")
        DropdownRow {
            title: I18n.tr("Provider")
            icon: "hub"
            target: page.a
            key: "provider"
            options: Ai.providers.map(x => ({ value: x.id, label: x.name }))
        }

        SettingRow {
            visible: !!page.p && page.p.kind === "anthropic" && !Ai.status.anthropicSdk
            title: I18n.tr("Needs the Anthropic SDK")
            subtitle: I18n.tr("Claude is reached through Anthropic's official Python SDK. Install python-anthropic (AUR), then press refresh.")
            icon: "warning"
            FIconButton { icon: "refresh"; size: 32; onClicked: Ai.refresh() }
        }

        SettingRow {
            visible: page.local
            title: page.p?.id === "lmstudio" ? I18n.tr("Start LM Studio's server") : I18n.tr("Run Ollama")
            subtitle: page.p?.id === "lmstudio" ? I18n.tr("In LM Studio: Developer → Start Server (port 1234), with a model loaded. Nothing leaves this computer.")
                : "Start it with `ollama serve` (or its systemd service) and pull a model, e.g. `ollama pull llama3.2`. Nothing leaves this computer."
            icon: "computer"
        }

        // server address (not for Claude)
        SettingRow {
            visible: !!page.p && page.p.kind === "openai"
            title: I18n.tr("Server address")
            subtitle: page.p && page.p.defaultBase ? I18n.tr("Default: ") + page.p.defaultBase : I18n.tr("The /v1 address of an OpenAI-compatible server")
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
            title: I18n.tr("API key")
            subtitle: !page.p ? "" : page.p.keyFrom === "keyring" ? I18n.tr("Saved in your keyring")
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
                    placeholder: page.p?.keyFrom ? I18n.tr("Replace the key") : I18n.tr("Paste the key")
                }
                FButton {
                    text: I18n.tr("Save")
                    disabled: keyField.text.trim() === ""
                    onClicked: {
                        Ai.saveKey(page.p.id, keyField.text.trim());
                        keyField.text = "";
                    }
                }
                FButton {
                    visible: page.p?.keyFrom === "keyring" || page.p?.keyFrom === "file"
                    text: I18n.tr("Remove")
                    variant: "text"
                    onClicked: Ai.deleteKey(page.p.id)
                }
            }
        }

        // model
        SettingRow {
            visible: !!page.p
            title: I18n.tr("Model")
            subtitle: page.modelInfo?.loading ? I18n.tr("Asking ") + (page.p?.name ?? "") + " for its models…"
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
                    placeholder: I18n.tr("Choose a model…")
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
            title: I18n.tr("Test the connection")
            subtitle: page.testInfo ? (page.testInfo.running ? I18n.tr("Asking the model to say ok…") : page.testInfo.text) : I18n.tr("Sends one short message")
            icon: page.testInfo && !page.testInfo.running ? (page.testInfo.ok ? "check_circle" : "error") : "network_check"
            FButton {
                text: I18n.tr("Test")
                variant: "tonal"
                disabled: !!page.testInfo?.running || !(page.p?.model)
                onClicked: Ai.test(page.p.id)
            }
        }
    }

    Group {
        title: I18n.tr("Behavior")
        TextRow {
            title: I18n.tr("Instructions")
            subtitle: I18n.tr("Sent before every conversation (the system prompt)")
            icon: "description"
            target: page.a
            key: "systemPrompt"
        }
        ChoiceRow {
            visible: page.p?.kind === "anthropic"
            title: I18n.tr("How hard Claude thinks")
            subtitle: I18n.tr("Higher is more thorough, but slower and uses more tokens")
            icon: "psychology"
            target: page.a
            key: "effort"
            options: [{ value: "low", label: I18n.tr("Quick") }, { value: "medium", label: I18n.tr("Balanced") }, { value: "high", label: I18n.tr("Thorough") }]
        }
        SettingRow {
            title: I18n.tr("Privacy")
            subtitle: page.local ? I18n.tr("Conversations stay on this computer.") : I18n.tr("What you type in the Assistant is sent to ") + (page.p?.name ?? "the provider") + ". Conversations aren't saved by Flamenco; they're gone when you clear them or restart the shell."
            icon: "shield"
        }
    }
}
