pragma Singleton

import QtQuick
import Quickshell

// Hand-tuned color schemes. Each has a dark and light variant using the
// same semantic roles, which map cleanly onto Qt's QPalette when exported.
Singleton {
    id: root

    // "noir" is shown as Flamenco (the shell's own black-and-grey look); "flamenco",
    // the original rose palette, is shown as Material Design (ids stay, so settings keep working)
    readonly property var names: ["noir", "flamenco", "glass", "y2k", "aero", "unity", "breeze", "catppuccin", "rosepine", "nord", "tokyonight", "gruvbox", "everforest", "dracula", "kanagawa", "solarized", "onedark", "monochrome"]

    readonly property var labels: ({
            noir: "Flamenco",
            flamenco: "Material Design",
            glass: "Liquid Glass",
            y2k: "Y2K",
            aero: "Frutiger Aero",
            unity: "Unity",
            breeze: "Breeze",
            catppuccin: "Catppuccin",
            rosepine: "Rosé Pine",
            nord: "Nord",
            tokyonight: "Tokyo Night",
            gruvbox: "Gruvbox",
            everforest: "Everforest",
            dracula: "Dracula",
            kanagawa: "Kanagawa",
            solarized: "Solarized",
            onedark: "One Dark",
            monochrome: "Monochrome",
            wallpaper: "From wallpaper"
        })

    readonly property var schemes: ({
            // Flamenco: near-black surfaces in steps of grey, a silver accent, and an
            // ember (accent3) for the few things that should glow
            noir: {
                dark: {
                    bg: "#0a0a0b", surface: "#141416", surfaceHigh: "#1d1d20", surfaceHighest: "#28282c",
                    border: "#303035", text: "#ececef", textDim: "#9c9ca4",
                    accent: "#d9d9df", onAccent: "#0e0e10", accent2: "#a7a7b0", accent3: "#ff7a5c",
                    error: "#ff6b6b", warning: "#e5b567", success: "#8fd19e"
                },
                light: {
                    bg: "#ececee", surface: "#f7f7f8", surfaceHigh: "#e4e4e7", surfaceHighest: "#d8d8dc",
                    border: "#c6c6cc", text: "#151517", textDim: "#5f5f66",
                    accent: "#26262a", onAccent: "#f7f7f8", accent2: "#55555c", accent3: "#d9532f",
                    error: "#c62828", warning: "#a66f00", success: "#2e7d4f"
                }
            },
            // Liquid Glass: Apple's system grays and blue (for the liquid glass finish, see-through panels)
            glass: {
                dark: {
                    bg: "#1c1c1e", surface: "#2c2c2e", surfaceHigh: "#3a3a3c", surfaceHighest: "#48484a",
                    border: "#545458", text: "#f5f5f7", textDim: "#a1a1a6",
                    accent: "#0a84ff", onAccent: "#ffffff", accent2: "#5e5ce6", accent3: "#64d2ff",
                    error: "#ff453a", warning: "#ff9f0a", success: "#30d158"
                },
                light: {
                    bg: "#f2f2f7", surface: "#ffffff", surfaceHigh: "#f2f2f7", surfaceHighest: "#e5e5ea",
                    border: "#c6c6c8", text: "#1d1d1f", textDim: "#6e6e73",
                    accent: "#007aff", onAccent: "#ffffff", accent2: "#5856d6", accent3: "#32ade6",
                    error: "#ff3b30", warning: "#ff9500", success: "#34c759"
                }
            },
            // Y2K: pearl and deep violet, hot pink, cyber cyan and lilac (with the chrome finish)
            y2k: {
                dark: {
                    bg: "#140f2b", surface: "#1e1838", surfaceHigh: "#2a2350", surfaceHighest: "#372e64",
                    border: "#4b4180", text: "#f3eeff", textDim: "#b6aee0",
                    accent: "#ff5fd2", onAccent: "#2a0425", accent2: "#41e2ff", accent3: "#c9a7ff",
                    error: "#ff5c7a", warning: "#ffd36b", success: "#7dffb2"
                },
                light: {
                    bg: "#e9e7f7", surface: "#f8f7ff", surfaceHigh: "#ecebfa", surfaceHighest: "#dedcf3",
                    border: "#c4c0e6", text: "#1d1838", textDim: "#5f5a86",
                    accent: "#e0249f", onAccent: "#ffffff", accent2: "#0090c8", accent3: "#7b4fd6",
                    error: "#d61d4a", warning: "#b37400", success: "#13915a"
                }
            },
            // Unity: Ubuntu's Ambiance (dark) and Radiance (light): warm greys, Ubuntu orange,
            // aubergine for the launcher's glass and the second accent
            unity: {
                dark: {
                    bg: "#2c2b28", surface: "#3c3b37", surfaceHigh: "#47463f", surfaceHighest: "#55534c",
                    border: "#5f5d55", text: "#f2f1f0", textDim: "#aea79f",
                    accent: "#e95420", onAccent: "#ffffff", accent2: "#77216f", accent3: "#5e2750",
                    error: "#df382c", warning: "#efb73e", success: "#38b44a"
                },
                light: {
                    bg: "#f2f1f0", surface: "#ffffff", surfaceHigh: "#e8e6e3", surfaceHighest: "#dfdbd2",
                    border: "#cdc8c1", text: "#3c3b37", textDim: "#7a776f",
                    accent: "#e95420", onAccent: "#ffffff", accent2: "#77216f", accent3: "#5e2750",
                    error: "#c7162b", warning: "#f99b11", success: "#0e8420"
                }
            },
            // Frutiger Aero: sky, aqua and grass green; ocean blues in the dark (with the gloss finish)
            aero: {
                dark: {
                    bg: "#06263a", surface: "#0b3350", surfaceHigh: "#114265", surfaceHighest: "#18537c",
                    border: "#2a6d99", text: "#e8f7ff", textDim: "#9cc7df",
                    accent: "#4cc3ff", onAccent: "#032033", accent2: "#7fe08f", accent3: "#4fe3d8",
                    error: "#ff6b63", warning: "#ffc04d", success: "#6fe08a"
                },
                light: {
                    bg: "#dff3ff", surface: "#f4fbff", surfaceHigh: "#e6f5ff", surfaceHighest: "#d2ecfb",
                    border: "#a9d4ee", text: "#0b2a3d", textDim: "#4a6f86",
                    accent: "#1e9bff", onAccent: "#ffffff", accent2: "#3cc85a", accent3: "#18c3c9",
                    error: "#e0443e", warning: "#e69a12", success: "#2fb54f"
                }
            },
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
            },
            dracula: {
                dark: {
                    bg: "#1e1f29", surface: "#282a36", surfaceHigh: "#323443", surfaceHighest: "#3d3f51",
                    border: "#44475a", text: "#f8f8f2", textDim: "#b4b6c8",
                    accent: "#bd93f9", onAccent: "#21222c", accent2: "#ff79c6", accent3: "#8be9fd",
                    error: "#ff5555", warning: "#ffb86c", success: "#50fa7b"
                },
                light: {
                    bg: "#f3f1f8", surface: "#fbfaff", surfaceHigh: "#ebe8f4", surfaceHighest: "#dfdbec",
                    border: "#cdc8de", text: "#282a36", textDim: "#6c6f85",
                    accent: "#7c4dcc", onAccent: "#ffffff", accent2: "#c2307f", accent3: "#1c8aa3",
                    error: "#d02b2b", warning: "#b8640d", success: "#1f8f45"
                }
            },
            kanagawa: {
                dark: {
                    bg: "#16161d", surface: "#1f1f28", surfaceHigh: "#2a2a37", surfaceHighest: "#363646",
                    border: "#3f3f52", text: "#dcd7ba", textDim: "#a6a69c",
                    accent: "#7e9cd8", onAccent: "#16161d", accent2: "#ffa066", accent3: "#957fb8",
                    error: "#e46876", warning: "#e6c384", success: "#98bb6c"
                },
                light: {
                    bg: "#e7dba0", surface: "#f2ecbc", surfaceHigh: "#e5ddb0", surfaceHighest: "#dcd5ac",
                    border: "#c7bd8f", text: "#545464", textDim: "#716e61",
                    accent: "#4d699b", onAccent: "#f2ecbc", accent2: "#cc6d00", accent3: "#624c83",
                    error: "#c84053", warning: "#836f4a", success: "#6f894e"
                }
            },
            solarized: {
                dark: {
                    bg: "#00212b", surface: "#002b36", surfaceHigh: "#073642", surfaceHighest: "#0d4351",
                    border: "#1b4e5b", text: "#eee8d5", textDim: "#93a1a1",
                    accent: "#268bd2", onAccent: "#fdf6e3", accent2: "#2aa198", accent3: "#d33682",
                    error: "#dc322f", warning: "#b58900", success: "#859900"
                },
                light: {
                    bg: "#eee8d5", surface: "#fdf6e3", surfaceHigh: "#f3ecd8", surfaceHighest: "#e6dfc9",
                    border: "#d6cfb8", text: "#073642", textDim: "#657b83",
                    accent: "#268bd2", onAccent: "#fdf6e3", accent2: "#2aa198", accent3: "#d33682",
                    error: "#dc322f", warning: "#b58900", success: "#859900"
                }
            },
            onedark: {
                dark: {
                    bg: "#1e2127", surface: "#282c34", surfaceHigh: "#2f343e", surfaceHighest: "#3a3f4b",
                    border: "#434956", text: "#dcdfe4", textDim: "#9da5b4",
                    accent: "#61afef", onAccent: "#1e2127", accent2: "#c678dd", accent3: "#56b6c2",
                    error: "#e06c75", warning: "#e5c07b", success: "#98c379"
                },
                light: {
                    bg: "#f0f0f1", surface: "#fafafa", surfaceHigh: "#eaeaeb", surfaceHighest: "#dfdfe1",
                    border: "#cfd0d4", text: "#383a42", textDim: "#696c77",
                    accent: "#4078f2", onAccent: "#ffffff", accent2: "#a626a4", accent3: "#0184bc",
                    error: "#e45649", warning: "#c18401", success: "#50a14f"
                }
            },
            monochrome: {
                dark: {
                    bg: "#0e0e0e", surface: "#171717", surfaceHigh: "#212121", surfaceHighest: "#2c2c2c",
                    border: "#3a3a3a", text: "#ededed", textDim: "#a0a0a0",
                    accent: "#e6e6e6", onAccent: "#111111", accent2: "#bdbdbd", accent3: "#8f8f8f",
                    error: "#ff6b6b", warning: "#e0b050", success: "#7cc489"
                },
                light: {
                    bg: "#f2f2f2", surface: "#ffffff", surfaceHigh: "#ebebeb", surfaceHighest: "#dedede",
                    border: "#cccccc", text: "#161616", textDim: "#666666",
                    accent: "#1f1f1f", onAccent: "#ffffff", accent2: "#474747", accent3: "#6e6e6e",
                    error: "#c62828", warning: "#a66f00", success: "#2e7d4f"
                }
            }
        })

    function get(name, dark) {
        const s = schemes[name] || schemes.flamenco;
        return dark ? s.dark : s.light;
    }
}
