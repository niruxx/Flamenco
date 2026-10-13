#!/usr/bin/env python3
"""Draw the README artwork (docs/assets/*.svg) from the shell's own palettes.

    tools/readme-assets.py [output-dir]      (default: docs/assets)

Everything is plain SVG so GitHub renders it inline; colors come from
shell/Commons/Palettes.qml, so the art follows palette changes. Re-run it
after editing the palettes.
"""
import re
import sys
from pathlib import Path
from xml.sax.saxutils import escape

ROOT = Path(__file__).resolve().parent.parent
OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "docs/assets"
FONT = "Inter, 'Google Sans', Roboto, 'Segoe UI', 'Helvetica Neue', Arial, sans-serif"
MONO = "'JetBrains Mono', 'Fira Code', Menlo, Consolas, monospace"


def load_palettes():
    src = (ROOT / "shell/Commons/Palettes.qml").read_text()
    names = re.findall(r'"([a-z]+)"', re.search(r"names:\s*\[(.*?)\]", src).group(1))
    labels = dict(re.findall(r'(\w+):\s*"([^"]+)"', re.search(r"labels:\s*\(\{(.*?)\}\)", src, re.S).group(1)))
    schemes = {}
    for name in names:
        block = src[src.index(f"{name}: {{", src.index("schemes:")):]
        variants = {}
        for mode in ("dark", "light"):
            body = re.search(mode + r":\s*\{(.*?)\}", block, re.S).group(1)
            variants[mode] = dict(re.findall(r'(\w+):\s*"(#[0-9a-fA-F]{6})"', body))
        schemes[name] = variants
    return names, labels, schemes


def svg(w, h, body, title):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}" '
            f'role="img" aria-label="{escape(title)}">\n<title>{escape(title)}</title>\n{body}\n</svg>\n')


def flame(x, y, s, fg, glow):
    """The Flamenco badge: gradient squircle + flame, top-left at (x, y), size s."""
    k = s / 128
    return f'''<g transform="translate({x} {y}) scale({k})">
  <rect x="8" y="8" width="112" height="112" rx="30" fill="url(#badge)"/>
  <path fill="{fg}" d="M64 20c6 18 26 30 26 56 0 19-12 32-26 32S38 95 38 77c0-13 7-22 13-28 0 11 4 18 11 20-5-15-3-33 2-49z"/>
  <path fill="{glow}" opacity=".85" d="M64 66c3 9 12 13 12 24 0 8-5 13-12 13s-12-5-12-12c0-6 3-10 6-13 0 5 2 8 5 9-2-7-1-14 1-21z"/>
</g>'''


def chip(x, y, text, p, filled=False):
    w = 22 + len(text) * 8.2
    bg = p["accent"] if filled else p["surfaceHighest"]
    fg = p["onAccent"] if filled else p["text"]
    return (f'<rect x="{x}" y="{y}" width="{w:.0f}" height="34" rx="17" fill="{bg}"/>'
            f'<text x="{x + w / 2:.0f}" y="{y + 22}" text-anchor="middle" font-family="{FONT}" font-size="14" '
            f'font-weight="600" fill="{fg}">{escape(text)}</text>'), w


def banner(p, mode):
    """Hero: badge, title, tagline and chips on the left; a stylized desktop on the right."""
    W, H = 1280, 440
    parts = [f'''<defs>
  <linearGradient id="badge" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="{p["accent"]}"/><stop offset="1" stop-color="{p["accent2"]}"/>
  </linearGradient>
  <radialGradient id="blobA" cx="0.5" cy="0.5" r="0.5">
    <stop offset="0" stop-color="{p["accent"]}" stop-opacity="{.38 if mode == "dark" else .22}"/>
    <stop offset="1" stop-color="{p["accent"]}" stop-opacity="0"/>
  </radialGradient>
  <radialGradient id="blobB" cx="0.5" cy="0.5" r="0.5">
    <stop offset="0" stop-color="{p["accent2"]}" stop-opacity="{.30 if mode == "dark" else .22}"/>
    <stop offset="1" stop-color="{p["accent2"]}" stop-opacity="0"/>
  </radialGradient>
  <radialGradient id="blobC" cx="0.5" cy="0.5" r="0.5">
    <stop offset="0" stop-color="{p["accent3"]}" stop-opacity="{.28 if mode == "dark" else .18}"/>
    <stop offset="1" stop-color="{p["accent3"]}" stop-opacity="0"/>
  </radialGradient>
  <linearGradient id="wall" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="{p["accent"]}" stop-opacity=".55"/>
    <stop offset=".55" stop-color="{p["accent3"]}" stop-opacity=".35"/>
    <stop offset="1" stop-color="{p["accent2"]}" stop-opacity=".5"/>
  </linearGradient>
  <clipPath id="card"><rect x="0" y="0" width="{W}" height="{H}" rx="32"/></clipPath>
  <clipPath id="screen"><rect x="700" y="56" width="520" height="328" rx="22"/></clipPath>
  <filter id="soft" x="-20%" y="-20%" width="140%" height="140%"><feDropShadow dx="0" dy="10" stdDeviation="14" flood-color="#000" flood-opacity="{.35 if mode == "dark" else .12}"/></filter>
</defs>
<g clip-path="url(#card)">
  <rect width="{W}" height="{H}" fill="{p["bg"]}"/>
  <circle cx="1040" cy="40" r="360" fill="url(#blobA)"/>
  <circle cx="160" cy="430" r="320" fill="url(#blobB)"/>
  <circle cx="620" cy="-40" r="240" fill="url(#blobC)"/>
</g>
<rect x="0.5" y="0.5" width="{W - 1}" height="{H - 1}" rx="32" fill="none" stroke="{p["border"]}"/>''']
    parts.append(flame(64, 70, 92, p["onAccent"], p["accent2"]))
    parts.append(f'<text x="64" y="232" font-family="{FONT}" font-size="64" font-weight="800" fill="{p["text"]}" letter-spacing="-1.5">Flamenco Shell</text>')
    parts.append(f'<text x="66" y="272" font-family="{FONT}" font-size="22" fill="{p["textDim"]}">A Material 3 desktop shell for niri and Hyprland,</text>')
    parts.append(f'<text x="66" y="302" font-family="{FONT}" font-size="22" fill="{p["textDim"]}">built with Quickshell.</text>')
    x = 64
    for i, t in enumerate(["niri", "Hyprland", "Material 3", "Quickshell", "Qt + GTK theming"]):
        c, w = chip(x, 338, t, p, filled=i == 0)
        parts.append(c)
        x += w + 10

    # stylized desktop: wallpaper, floating bar, two windows, a control center card
    parts.append(f'''<g filter="url(#soft)"><rect x="700" y="56" width="520" height="328" rx="22" fill="{p["surface"]}"/></g>
<g clip-path="url(#screen)">
  <rect x="700" y="56" width="520" height="328" fill="url(#wall)"/>
  <circle cx="1150" cy="330" r="120" fill="{p["accent"]}" opacity=".25"/>
  <circle cx="780" cy="120" r="90" fill="{p["accent2"]}" opacity=".18"/>
</g>
<rect x="714" y="68" width="492" height="30" rx="15" fill="{p["surface"]}" opacity=".94"/>
<rect x="726" y="76" width="14" height="14" rx="4" fill="{p["accent"]}"/>
<rect x="750" y="78" width="66" height="10" rx="5" fill="{p["surfaceHighest"]}"/>
<rect x="754" y="80" width="22" height="6" rx="3" fill="{p["accent"]}"/>
<circle cx="786" cy="83" r="3" fill="{p["textDim"]}"/><circle cx="798" cy="83" r="3" fill="{p["textDim"]}" opacity=".5"/>
<text x="960" y="88" text-anchor="middle" font-family="{FONT}" font-size="12" font-weight="700" fill="{p["text"]}">9:41</text>
<rect x="1120" y="78" width="10" height="10" rx="5" fill="{p["textDim"]}"/><rect x="1138" y="78" width="10" height="10" rx="5" fill="{p["textDim"]}"/>
<rect x="1156" y="78" width="10" height="10" rx="5" fill="{p["textDim"]}"/><rect x="1176" y="76" width="20" height="14" rx="7" fill="{p["accent"]}"/>
<g filter="url(#soft)">
  <rect x="716" y="112" width="250" height="256" rx="16" fill="{p["surface"]}"/>
  <rect x="978" y="112" width="104" height="256" rx="16" fill="{p["surface"]}" opacity=".9"/>
</g>
<rect x="716" y="112" width="250" height="256" rx="16" fill="none" stroke="{p["accent"]}" stroke-width="2.5"/>
<rect x="732" y="128" width="84" height="10" rx="5" fill="{p["text"]}" opacity=".85"/>
<rect x="732" y="148" width="200" height="8" rx="4" fill="{p["textDim"]}" opacity=".6"/>
<rect x="732" y="164" width="170" height="8" rx="4" fill="{p["textDim"]}" opacity=".6"/>
<rect x="732" y="186" width="218" height="96" rx="12" fill="{p["surfaceHigh"]}"/>
<path d="M744 262 L770 236 L792 252 L826 214 L860 240 L890 222 L938 248" fill="none" stroke="{p["accent"]}" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
<rect x="732" y="296" width="100" height="8" rx="4" fill="{p["textDim"]}" opacity=".6"/>
<rect x="732" y="316" width="70" height="30" rx="15" fill="{p["accent"]}"/>
<rect x="810" y="316" width="70" height="30" rx="15" fill="{p["surfaceHighest"]}"/>
<rect x="992" y="128" width="60" height="8" rx="4" fill="{p["textDim"]}" opacity=".6"/>
<rect x="992" y="146" width="76" height="60" rx="10" fill="{p["surfaceHigh"]}"/>
<rect x="992" y="216" width="76" height="60" rx="10" fill="{p["surfaceHigh"]}"/>
<rect x="992" y="286" width="76" height="60" rx="10" fill="{p["surfaceHigh"]}"/>
<g filter="url(#soft)"><rect x="1094" y="112" width="114" height="190" rx="18" fill="{p["surfaceHigh"]}"/></g>
<rect x="1104" y="124" width="44" height="40" rx="12" fill="{p["accent"]}"/>
<rect x="1154" y="124" width="44" height="40" rx="12" fill="{p["surfaceHighest"]}"/>
<rect x="1104" y="170" width="44" height="40" rx="12" fill="{p["surfaceHighest"]}"/>
<rect x="1154" y="170" width="44" height="40" rx="12" fill="{p["accent2"]}" opacity=".85"/>
<rect x="1106" y="228" width="90" height="12" rx="6" fill="{p["surfaceHighest"]}"/>
<rect x="1106" y="228" width="60" height="12" rx="6" fill="{p["accent"]}"/>
<rect x="1106" y="252" width="90" height="12" rx="6" fill="{p["surfaceHighest"]}"/>
<rect x="1106" y="252" width="38" height="12" rx="6" fill="{p["accent"]}"/>
<rect x="1106" y="276" width="56" height="8" rx="4" fill="{p["textDim"]}" opacity=".6"/>''')
    return svg(W, H, "\n".join(parts), "Flamenco Shell: a Material 3 desktop shell for niri and Hyprland")


def palettes(names, labels, schemes, mode):
    """Every palette as a small Material 3 card: surface, accent swatches and a tonal button."""
    cols, cw, ch, gap = 4, 300, 150, 20
    rows = (len(names) + cols - 1) // cols
    W, H = cols * cw + (cols - 1) * gap, rows * ch + (rows - 1) * gap
    parts = []
    for i, n in enumerate(names):
        p = schemes[n][mode]
        x, y = (i % cols) * (cw + gap), (i // cols) * (ch + gap)
        parts.append(f'''<g transform="translate({x} {y})">
  <rect x=".5" y=".5" width="{cw - 1}" height="{ch - 1}" rx="22" fill="{p["bg"]}" stroke="{p["border"]}"/>
  <rect x="14" y="14" width="{cw - 28}" height="70" rx="16" fill="{p["surfaceHigh"]}"/>
  <circle cx="44" cy="49" r="18" fill="{p["accent"]}"/>
  <circle cx="72" cy="49" r="18" fill="{p["accent2"]}" stroke="{p["surfaceHigh"]}" stroke-width="3"/>
  <circle cx="100" cy="49" r="18" fill="{p["accent3"]}" stroke="{p["surfaceHigh"]}" stroke-width="3"/>
  <rect x="134" y="38" width="{cw - 172}" height="8" rx="4" fill="{p["text"]}" opacity=".85"/>
  <rect x="134" y="54" width="{cw - 210}" height="8" rx="4" fill="{p["textDim"]}" opacity=".7"/>
  <text x="22" y="120" font-family="{FONT}" font-size="18" font-weight="700" fill="{p["text"]}">{escape(labels.get(n, n))}</text>
  <rect x="{cw - 92}" y="100" width="72" height="30" rx="15" fill="{p["accent"]}"/>
  <text x="{cw - 56}" y="120" text-anchor="middle" font-family="{FONT}" font-size="13" font-weight="700" fill="{p["onAccent"]}">{mode.title()}</text>
</g>''')
    return svg(W, H, "\n".join(parts), f"The {len(names)} Flamenco palettes ({mode})")


def main():
    names, labels, schemes = load_palettes()
    OUT.mkdir(parents=True, exist_ok=True)
    files = {}
    for mode in ("dark", "light"):
        p = schemes["flamenco"][mode]
        files[f"banner-{mode}.svg"] = banner(p, mode)
        files[f"palettes-{mode}.svg"] = palettes(names, labels, schemes, mode)
    for name, text in files.items():
        (OUT / name).write_text(text)
    print(f"wrote {len(files)} files to {OUT}")


if __name__ == "__main__":
    main()
