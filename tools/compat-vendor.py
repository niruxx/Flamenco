#!/usr/bin/env python3
"""Vendor what Noctalia Shell v4 and DankMaterialShell plugins build on into
shell/Compat/, so Flamenco can run those plugins (Settings → Plugins (3rd party)).

Both projects are MIT licensed. Their files are copied as they are, with their
`qs.*` imports pointed at the copies (qs.Commons → qs.Compat.Noctalia.Commons)
and a few small patches (below). Flamenco's own replacements for the rest
(colors, settings, services) are hand-written files next to them; this never
touches a file it didn't copy (the list is in each kind's VENDORED file).

usage:
  tools/compat-vendor.py noctalia PATH   copy from a Noctalia v4 checkout (branch legacy-v4)
  tools/compat-vendor.py dms PATH        copy from a DankMaterialShell v1.6 checkout
                                         (git clone --recurse-submodules -b v1.6.3 …)
  tools/compat-vendor.py --check         list types and singletons nothing provides
"""
import pathlib
import re
import shutil
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent / "shell"
COMPAT = ROOT / "Compat"

# what to copy: (source glob, destination folder under Compat/<Kind>)
SOURCES = {
    "noctalia": {
        "kind": "Noctalia",
        "license": "LICENSE",
        "upstream": "https://github.com/noctalia-dev/noctalia-shell (branch legacy-v4)",
        "files": [
            ("Widgets/*.qml", "Widgets"),
            ("Modules/Bar/Extras/BarPill.qml", "Modules/Bar/Extras"),
            ("Modules/Bar/Extras/BarPillHorizontal.qml", "Modules/Bar/Extras"),
            ("Modules/Bar/Extras/BarPillVertical.qml", "Modules/Bar/Extras"),
            ("Modules/Tooltip/Tooltip.qml", "Modules/Tooltip"),
            ("Commons/Style.qml", "Commons"),
            ("Commons/Icons.qml", "Commons"),
            ("Commons/IconsTabler.qml", "Commons"),
            ("Commons/FuzzySort.qml", "Commons"),
            ("Commons/Keybinds.qml", "Commons"),
            ("Commons/Logger.qml", "Commons"),
            ("Commons/Time.qml", "Commons"),
            ("Services/UI/TooltipService.qml", "Services/UI"),
            ("Helpers/*.js", "Helpers"),
            ("Assets/Fonts/tabler/*", "Assets/Fonts/tabler"),
            ("Assets/Translations/en.json", "Assets/Translations"),
            ("Assets/settings-default.json", "Assets"),
        ],
        # widgets that need parts of Noctalia Flamenco doesn't have; left out
        "skip": {"NPluginSettingsPopup.qml", "NSectionEditor.qml", "NWidgetSettingsPopup.qml"},
        "patches": {
            # the tabler font is in the compat folder, not at the shell's root
            "Commons/Icons.qml": [('"/Assets/Fonts/tabler/', '"/Compat/Noctalia/Assets/Fonts/tabler/')],
            # bar sizes follow Flamenco's bar (Settings → Bar → Thickness), not Noctalia's densities
            "Commons/Style.qml": [
                ("import Quickshell\n", "import Quickshell\nimport qs.Commons as Flamenco\n"),
                (re.compile(r"readonly property real barHeight: \{.*?\n  \}\n", re.S),
                 "readonly property real barHeight: toOdd(Flamenco.Theme.barHeight)\n"),
                ("function getBarHeightForDensity(density, isVertical) {\n",
                 "function getBarHeightForDensity(density, isVertical) {\n    return toOdd(Flamenco.Theme.barHeight);\n"),
            ],
        },
    },
    "dms": {
        "kind": "Dms",
        "license": "LICENSE",
        # DMS 1.6 (the release most plugins target), with its dank-qml-common submodule
        "upstream": "https://github.com/AvengeMedia/DankMaterialShell (v1.6) and dank-qml-common (stable-1.6)",
        "files": [
            ("dank-qml-common/LICENSE", "DankCommon"),
            ("dank-qml-common/DankCommon/Widgets/*.qml", "DankCommon/Widgets"),
            ("dank-qml-common/DankCommon/Widgets/*.js", "DankCommon/Widgets"),
            ("dank-qml-common/DankCommon/Common/*.qml", "DankCommon/Common"),
            ("dank-qml-common/DankCommon/Common/*.js", "DankCommon/Common"),
            ("dank-qml-common/DankCommon/Modals/FileBrowser/*.qml", "DankCommon/Modals/FileBrowser"),
            ("quickshell/Modals/FileBrowser/*.qml", "Modals/FileBrowser"),
            ("quickshell/Modals/Common/*.qml", "Modals/Common"),
            ("quickshell/Widgets/*.qml", "Widgets"),
            ("quickshell/Modules/Plugins/*.qml", "Modules/Plugins"),
            ("quickshell/Common/Proc.qml", "Common"),
            ("quickshell/Common/Appearance.qml", "Common"),
            ("quickshell/Common/Anims.qml", "Common"),
            ("quickshell/Common/DeferredAction.qml", "Common"),
            ("quickshell/Common/Ref.qml", "Common"),
            ("quickshell/Common/QmlUtils.js", "Common"),
            ("quickshell/Services/Log.qml", "Services"),
        ],
        "skip": {
            # Flamenco's own: the bar pill, the popout and the plugin root are hosted by Flamenco
            "PluginComponent.qml", "BasePill.qml", "PluginPopout.qml", "DesktopPluginWrapper.qml",
            # parts of DMS's own surfaces (OSD, popouts, media art, launcher) no plugin uses
            "DankAlbumArt.qml", "DankAnimatedAlbumArt.qml", "MediaArtBackdrop.qml", "MediaBlobHalo.qml", "MediaArtwork.qml",
            "DankOSD.qml", "DankPopout.qml", "DankPopoutConnected.qml", "DankPopoutStandalone.qml", "DankBackdrop.qml",
            "BackdropBlur.qml", "BatteryMeter.qml", "ScrollingText.qml", "AppLauncherGridDelegate.qml",
            "AppLauncherListDelegate.qml", "PopoutHoverBodyTracker.qml", "PopoutHoverDismiss.qml",
            "TransientSurfaceTracker.qml", "HoverDismissTracker.qml", "DismissZone.qml", "DankSlideout.qml",
            "DankSeekbar.qml", "LauncherLogo.qml",
            # Flamenco's fonts instead of the ones DMS bundles
            "Fonts.qml",
            # Flamenco's own modal (DMS's needs its frame and layer management)
            "DankModal.qml", "DankModalConnected.qml", "DankModalStandalone.qml",
        },
        "patches": {},
    },
}

HEADER = "// Vendored from {upstream} (MIT) by tools/compat-vendor.py.\n// Don't edit: change the vendoring tool or a Flamenco shim next to it.\n"


def rewrite_imports(text: str, kind: str) -> str:
    return re.sub(r"(?m)^(\s*import\s+)qs\.(?!Compat\.)", rf"\1qs.Compat.{kind}.", text)


def vendor(which: str, src: pathlib.Path):
    spec = SOURCES[which]
    kind = spec["kind"]
    dest_root = COMPAT / kind
    listing = dest_root / "VENDORED"
    # forget the files copied last time, so ones dropped upstream go away
    if listing.is_file():
        for rel in listing.read_text().split():
            (dest_root / rel).unlink(missing_ok=True)
    copied = []
    for pattern, dest in spec["files"]:
        matches = sorted(src.glob(pattern))
        if not matches:
            print(f"warning: nothing matches {pattern}", file=sys.stderr)
        for f in matches:
            if not f.is_file() or f.name in spec["skip"]:
                continue
            out = dest_root / dest / f.name
            if out.exists() and str(out.relative_to(dest_root)) not in copied:
                # a hand-written shim with this name wins
                if not listing.is_file() or str(out.relative_to(dest_root)) not in listing.read_text().split():
                    print(f"keeping Flamenco's own {out.relative_to(ROOT)}")
                    continue
            out.parent.mkdir(parents=True, exist_ok=True)
            rel = str(out.relative_to(dest_root))
            if f.suffix in (".qml", ".js"):
                text = f.read_text()
                text = rewrite_imports(text, kind)
                for old, new in spec["patches"].get(f"{dest}/{f.name}", []):
                    if isinstance(old, re.Pattern):
                        text, n = old.subn(lambda _m: new, text, count=1)
                    else:
                        n = text.count(old)
                        text = text.replace(old, new)
                    if not n:
                        print(f"warning: patch for {rel} doesn't apply: {old!r}", file=sys.stderr)
                head = HEADER.format(upstream=spec["upstream"])
                # pragmas and .pragma library lines must stay first
                lines = text.split("\n")
                n = 0
                while n < len(lines) and (lines[n].startswith("pragma") or lines[n].startswith(".pragma") or lines[n].startswith(".import")):
                    n += 1
                text = "\n".join(lines[:n] + [head.rstrip("\n")] + lines[n:])
                out.write_text(text)
            else:
                shutil.copyfile(f, out)
            copied.append(rel)
    lic = src / spec["license"]
    if lic.is_file():
        shutil.copyfile(lic, dest_root / "LICENSE")
    listing.write_text("\n".join(sorted(set(copied))) + "\n")
    print(f"{kind}: {len(copied)} files from {src}")


# ── --check: types and singletons used in Compat/ that nothing defines ──
KNOWN_TYPES = set("""
Item Rectangle Text TextInput TextEdit Image AnimatedImage BorderImage Row Column Flow Grid Repeater Loader MouseArea Timer
Behavior NumberAnimation ColorAnimation SequentialAnimation ParallelAnimation PauseAnimation PropertyAction RotationAnimation
SmoothedAnimation SpringAnimation ScriptAction PropertyAnimation AnchorAnimation FrameAnimation Canvas Transition Connections
Component QtObject Binding Gradient GradientStop Translate Scale Rotation ListView GridView PathView Flickable ListModel
ListElement HoverHandler DragHandler WheelHandler TapHandler PointHandler PinchHandler FontLoader FontMetrics TextMetrics
MultiEffect ShaderEffect ShaderEffectSource RowLayout ColumnLayout GridLayout StackLayout State PropertyChanges AnchorChanges
StateGroup Instantiator DelegateModel ObjectModel Keys FocusScope DropArea Drag Shortcut Accessible LayoutMirroring
Window Screen IntValidator DoubleValidator RegularExpressionValidator Path PathLine PathArc PathQuad PathCubic PathMove
PathSvg PathAngleArc PathText Shape ShapePath LinearGradient RadialGradient ConicalGradient FolderListModel SystemPalette
Popup ScrollView ScrollBar ScrollIndicator Slider RangeSlider ComboBox TextField TextArea Button RoundButton ToolButton
Switch CheckBox RadioButton SpinBox Menu MenuItem MenuSeparator ToolTip Label Control AbstractButton ItemDelegate Pane
Frame BusyIndicator ProgressBar StackView SwipeView TabBar TabButton Dialog Overlay Drawer SplitView Tumbler DelayButton
ButtonGroup Action ActionGroup Page ToolBar ToolSeparator PageIndicator SwitchDelegate CheckDelegate MenuBar
ShellRoot Scope Variants PanelWindow FloatingWindow PopupWindow LazyLoader Singleton SystemClock Process StdioCollector
SplitParser FileView JsonAdapter JsonObject IpcHandler Region PwObjectTracker NotificationServer WlSessionLock
WlSessionLockSurface PamContext IdleMonitor ClippingRectangle ClippingWrapperRectangle WrapperRectangle WrapperItem
WrapperMouseArea MarginWrapperManager IconImage QsMenuOpener QsMenuAnchor ScriptModel PersistentProperties Socket
ScreencopyView HyprlandFocusGrab DesktopEntries Retainable RetainableLock ElapsedTimer PopupAnchor ColorQuantizer DataStream
""".split())
GLOBALS = set("""
Qt Math JSON Date Object Array String Number Boolean Promise RegExp Error Infinity NaN Map Set Symbol Intl Uint8Array
Quickshell Hyprland Niri Pipewire PwNodeType PwLinkState UPower UPowerDeviceType UPowerDeviceState PowerProfile PowerProfiles
Mpris MprisPlaybackState Notifications NotificationUrgency SystemTray Bluetooth BluetoothDeviceState NetworkManager
ToplevelManager WlrLayer WlrKeyboardFocus WlrLayershell ExclusionMode Edges Image Text Font Easing ScrollBar Flickable
ListView GridView Item Animation Layout Keys Drag Component Loader Shape ShapePath TextInput TextEdit Popup Window
QsWindow Process FileViewError FolderListModel Accessible ItemSelectionModel DragHandler PathView Slider ComboBox
StandardPaths Locale TapHandler PointerDevice Gradient Screen Transition AbstractButton Overlay Control TextField
StackView SwipeView ListModel Grid Flow Repeater Row Column FontInfo FontDatabase Region RegionShape Intersection
KeyNavigation BackgroundEffect PopupAdjustment JSON5 TextArea PointHandler MouseArea Application Menu Dialog Switch
""".split())


def strip_code(t: str) -> str:
    t = re.sub(r"/\*.*?\*/", "", t, flags=re.S)
    t = re.sub(r"//[^\n]*", "", t)
    t = re.sub(r"`(?:\\.|[^`\\])*`", '""', t, flags=re.S)
    t = re.sub(r'"(?:\\.|[^"\\\n])*"', '""', t)
    t = re.sub(r"'(?:\\.|[^'\\\n])*'", "''", t)
    return t


def check() -> int:
    problems = {}
    for kind_dir in sorted(p for p in COMPAT.iterdir() if p.is_dir()):
        kind = kind_dir.name
        # module dir (relative) → type names it defines
        mods: dict[str, set[str]] = {}
        singletons: set[str] = set()
        for f in kind_dir.rglob("*.qml"):
            mods.setdefault(f.parent.relative_to(kind_dir).as_posix(), set()).add(f.stem)
            if re.search(r"(?m)^pragma Singleton", f.read_text()):
                singletons.add(f.stem)
        for f in sorted(kind_dir.rglob("*.qml")):
            raw = f.read_text()
            text = strip_code(raw)
            here = f.parent.relative_to(kind_dir).as_posix()
            avail = set(mods.get(here, set()))
            for m in re.finditer(rf"(?m)^\s*import\s+qs\.Compat\.{kind}\.([\w.]+)", raw):
                avail |= mods.get(m.group(1).replace(".", "/"), {"__missing_module__" + m.group(1)})
                if m.group(1).replace(".", "/") not in mods:
                    problems.setdefault(f"{kind}: missing module qs.Compat.{kind}.{m.group(1)}", set()).add(f.name)
            for m in re.finditer(r'(?m)^\s*import\s+"([^"]+)"', raw):
                d = (f.parent / m.group(1)).resolve()
                if d.is_dir():
                    avail |= {g.stem for g in d.glob("*.qml")}
            body = re.sub(r"(?m)^\s*(import|pragma)\b.*$", "", text)
            # inline components, enums and JS imports (`import "x.js" as Name`) count as defined
            avail |= set(re.findall(r"\bcomponent\s+([A-Z]\w*)\s*:", text))
            avail |= set(re.findall(r"\benum\s+([A-Z]\w*)", text))
            avail |= set(re.findall(r'(?m)^\s*import\s+(?:"[^"]+"|[\w.]+)(?:\s+[\d.]+)?\s+as\s+([A-Z]\w*)', raw))
            for m in re.finditer(r"(?:^|[\s:;{(,\[])([A-Z]\w*)\s*\{", body):
                t = m.group(1)
                if t not in KNOWN_TYPES and t not in avail:
                    problems.setdefault(f"{kind}: type {t}", set()).add(f.relative_to(kind_dir).as_posix())
            for m in re.finditer(r"(?<![\w.])([A-Z]\w*)\.(\w+)", body):
                n = m.group(1)
                if n in GLOBALS or n in KNOWN_TYPES or n in avail:
                    continue
                if n in singletons:
                    problems.setdefault(f"{kind}: singleton {n} not imported", set()).add(f.relative_to(kind_dir).as_posix())
                    continue
                problems.setdefault(f"{kind}: singleton {n}", set()).add(f.relative_to(kind_dir).as_posix())
    for k in sorted(problems):
        files = sorted(problems[k])
        print(f"{k}  ({len(files)}: {', '.join(files[:4])}{' …' if len(files) > 4 else ''})")
    print(f"{len(problems)} unresolved")
    return 1 if problems else 0


if __name__ == "__main__":
    a = sys.argv[1:]
    if a[:1] == ["--check"]:
        sys.exit(check())
    if len(a) == 2 and a[0] in SOURCES:
        vendor(a[0], pathlib.Path(a[1]).expanduser().resolve())
        sys.exit(0)
    print(__doc__)
    sys.exit(2)
