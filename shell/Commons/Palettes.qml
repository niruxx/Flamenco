pragma Singleton

import QtQuick
import Quickshell

// Hand-tuned color schemes. Each has a dark and light variant using the
// same semantic roles, which map cleanly onto Qt's QPalette when exported.
Singleton {
    id: root

    readonly property var names: ["flamenco", "breeze", "catppuccin", "rosepine", "nord", "tokyonight", "gruvbox", "everforest"]

    readonly property var labels: ({
            flamenco: "Flamenco",
            breeze: "Breeze",
            catppuccin: "Catppuccin",
            rosepine: "Rosé Pine",
            nord: "Nord",
            tokyonight: "Tokyo Night",
            gruvbox: "Gruvbox",
            everforest: "Everforest",
            wallpaper: "From wallpaper"
        })

    readonly property var schemes: ({
            flamenco: {
                dark: {
                    bg: "#140f10", surface: "#1d1617", surfaceHigh: "#281e20", surfaceHighest: "#34272a",
                    border: "#46343a", text: "#f5e9e7", textDim: "#b9a3a2",
                    accent: "#ff5d73", onAccent: "#2a0910", accent2: "#ffb867", accent3: "#e98aa8",
                    error: "#ff6b6b", warning: "#ffb867", success: "#8bd5a0"
                },
                light: {
                    bg: "#fbf3f1", surface: "#ffffff", surfaceHigh: "#f4e8e5", surfaceHighest: "#ebdad6",
                    border: "#ddc6c2", text: "#2b1b1c", textDim: "#7b6564",
                    accent: "#d0304d", onAccent: "#ffffff", accent2: "#b8740f", accent3: "#a8456a",
                    error: "#c62828", warning: "#b8740f", success: "#2e7d4f"
                }
            },
            breeze: {
                dark: {
                    bg: "#1b1e20", surface: "#232629", surfaceHigh: "#2a2e32", surfaceHighest: "#31363b",
                    border: "#3f454b", text: "#fcfcfc", textDim: "#a1a9b1",
                    accent: "#3daee9", onAccent: "#0d1a21", accent2: "#1d99f3", accent3: "#c678dd",
                    error: "#da4453", warning: "#f67400", success: "#27ae60"
                },
                light: {
                    bg: "#eff0f1", surface: "#fcfcfc", surfaceHigh: "#e3e5e7", surfaceHighest: "#d6d9dc",
                    border: "#c3c7cb", text: "#232629", textDim: "#707d8a",
                    accent: "#3daee9", onAccent: "#ffffff", accent2: "#1d99f3", accent3: "#8e44ad",
                    error: "#da4453", warning: "#f67400", success: "#27ae60"
                }
            },
            catppuccin: {
                dark: {
                    bg: "#11111b", surface: "#1e1e2e", surfaceHigh: "#313244", surfaceHighest: "#45475a",
                    border: "#3b3d52", text: "#cdd6f4", textDim: "#a6adc8",
                    accent: "#cba6f7", onAccent: "#1e1e2e", accent2: "#f5c2e7", accent3: "#89b4fa",
                    error: "#f38ba8", warning: "#fab387", success: "#a6e3a1"
                },
                light: {
                    bg: "#dce0e8", surface: "#eff1f5", surfaceHigh: "#e6e9ef", surfaceHighest: "#ccd0da",
                    border: "#bcc0cc", text: "#4c4f69", textDim: "#6c6f85",
                    accent: "#8839ef", onAccent: "#eff1f5", accent2: "#ea76cb", accent3: "#1e66f5",
                    error: "#d20f39", warning: "#fe640b", success: "#40a02b"
                }
            },
            rosepine: {
                dark: {
                    bg: "#191724", surface: "#1f1d2e", surfaceHigh: "#26233a", surfaceHighest: "#312d48",
                    border: "#403d52", text: "#e0def4", textDim: "#908caa",
                    accent: "#ebbcba", onAccent: "#191724", accent2: "#c4a7e7", accent3: "#9ccfd8",
                    error: "#eb6f92", warning: "#f6c177", success: "#9ccfd8"
                },
                light: {
                    bg: "#faf4ed", surface: "#fffaf3", surfaceHigh: "#f2e9e1", surfaceHighest: "#e9dfd6",
                    border: "#dfdad9", text: "#575279", textDim: "#797593",
                    accent: "#d7827e", onAccent: "#fffaf3", accent2: "#907aa9", accent3: "#56949f",
                    error: "#b4637a", warning: "#ea9d34", success: "#286983"
                }
            },
            nord: {
                dark: {
                    bg: "#242933", surface: "#2e3440", surfaceHigh: "#3b4252", surfaceHighest: "#434c5e",
                    border: "#4c566a", text: "#eceff4", textDim: "#aab3c4",
                    accent: "#88c0d0", onAccent: "#2e3440", accent2: "#81a1c1", accent3: "#b48ead",
                    error: "#bf616a", warning: "#ebcb8b", success: "#a3be8c"
                },
                light: {
                    bg: "#e5e9f0", surface: "#eceff4", surfaceHigh: "#dfe3eb", surfaceHighest: "#d8dee9",
                    border: "#c2c9d6", text: "#2e3440", textDim: "#4c566a",
                    accent: "#5e81ac", onAccent: "#eceff4", accent2: "#81a1c1", accent3: "#b48ead",
                    error: "#bf616a", warning: "#d08770", success: "#7c9a5e"
                }
            },
            tokyonight: {
                dark: {
                    bg: "#16161e", surface: "#1a1b26", surfaceHigh: "#24283b", surfaceHighest: "#2f3549",
                    border: "#3b4261", text: "#c0caf5", textDim: "#a9b1d6",
                    accent: "#7aa2f7", onAccent: "#16161e", accent2: "#bb9af7", accent3: "#7dcfff",
                    error: "#f7768e", warning: "#e0af68", success: "#9ece6a"
                },
                light: {
                    bg: "#d0d5e3", surface: "#e1e2e7", surfaceHigh: "#d5d6db", surfaceHighest: "#c4c8da",
                    border: "#a8aecb", text: "#3760bf", textDim: "#6172b0",
                    accent: "#2e7de9", onAccent: "#e1e2e7", accent2: "#9854f1", accent3: "#007197",
                    error: "#f52a65", warning: "#8c6c3e", success: "#587539"
                }
            },
            gruvbox: {
                dark: {
                    bg: "#1d2021", surface: "#282828", surfaceHigh: "#32302f", surfaceHighest: "#3c3836",
                    border: "#504945", text: "#ebdbb2", textDim: "#a89984",
                    accent: "#fe8019", onAccent: "#1d2021", accent2: "#fabd2f", accent3: "#83a598",
                    error: "#fb4934", warning: "#fabd2f", success: "#b8bb26"
                },
                light: {
                    bg: "#f2e5bc", surface: "#fbf1c7", surfaceHigh: "#ebdbb2", surfaceHighest: "#d5c4a1",
                    border: "#bdae93", text: "#3c3836", textDim: "#7c6f64",
                    accent: "#af3a03", onAccent: "#fbf1c7", accent2: "#b57614", accent3: "#076678",
                    error: "#9d0006", warning: "#b57614", success: "#79740e"
                }
            },
            everforest: {
                dark: {
                    bg: "#232a2e", surface: "#2d353b", surfaceHigh: "#343f44", surfaceHighest: "#3d484d",
                    border: "#475258", text: "#d3c6aa", textDim: "#9da9a0",
                    accent: "#a7c080", onAccent: "#232a2e", accent2: "#83c092", accent3: "#d699b6",
                    error: "#e67e80", warning: "#dbbc7f", success: "#a7c080"
                },
                light: {
                    bg: "#efebd4", surface: "#fdf6e3", surfaceHigh: "#f4f0d9", surfaceHighest: "#e6e2cc",
                    border: "#d8d3ba", text: "#5c6a72", textDim: "#829181",
                    accent: "#8da101", onAccent: "#fdf6e3", accent2: "#35a77c", accent3: "#df69ba",
                    error: "#f85552", warning: "#dfa000", success: "#8da101"
                }
            }
        })

    function get(name, dark) {
        const s = schemes[name] || schemes.flamenco;
        return dark ? s.dark : s.light;
    }
}
