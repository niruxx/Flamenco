#!/usr/bin/env python3
"""Static sanity checks for the shell's QML (no Qt needed).

Catches the load-time errors we've actually hit:
  - unbalanced braces / parens / brackets
  - object types that aren't defined in the shell or a known module
  - `Behavior on` a readonly property            (QML refuses to load)
  - `Behavior` attached to a non-Item object      (Qt 6.12 segfaults)
  - shell types used without importing their module ("X is not a type")
  - child objects in a type with no default property ("Cannot assign to
    non-existent default property"), e.g. a Timer inside a WheelHandler

usage: tools/qmlcheck.py [shell-dir]
"""
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else pathlib.Path(__file__).resolve().parent.parent / "shell")
files = sorted(root.rglob("*.qml"))
defined = {f.stem for f in files}
# type name -> folders (relative to the shell root) that define it
homes: dict[str, set[str]] = {}
for f in files:
    homes.setdefault(f.stem, set()).add(f.parent.relative_to(root).as_posix())

KNOWN = set("""
Item Rectangle Text TextInput TextEdit Image Row Column Flow Grid Repeater Loader MouseArea Timer Behavior
NumberAnimation ColorAnimation SequentialAnimation ParallelAnimation PauseAnimation PropertyAction RotationAnimation FrameAnimation Canvas
Transition Connections Component QtObject Binding Gradient GradientStop Translate ListView GridView Flickable ListModel
HoverHandler DragHandler WheelHandler TapHandler FontLoader MultiEffect RowLayout ColumnLayout GridLayout
ShellRoot Scope Variants PanelWindow FloatingWindow PopupWindow LazyLoader Singleton SystemClock Process StdioCollector
SplitParser FileView JsonAdapter JsonObject IpcHandler Region PwObjectTracker PwNodeLinkTracker NotificationServer WlSessionLock
WlSessionLockSurface PamContext IdleMonitor PolkitAgent ClippingRectangle IconImage QsMenuOpener Shortcut ScriptModel PersistentProperties Socket
ScreencopyView DropArea
ComboBox Popup ItemDelegate ShaderEffectSource ShaderEffect Slider RangeSlider Shape ShapePath PathLine PathArc PathQuad
PathCubic PathMove PathSvg PathAngleArc LinearGradient RadialGradient ConicalGradient IntValidator DoubleValidator
RegularExpressionValidator Control TextField TextArea ScrollView ScrollBar ScrollIndicator Button RoundButton ToolButton
Switch CheckBox RadioButton SpinBox Menu MenuItem MenuSeparator ToolTip Label AbstractButton Pane Frame BusyIndicator
ProgressBar StackView SwipeView TabBar TabButton Dialog Drawer SplitView ButtonGroup Action Page ToolBar Overlay
AnimatedImage BorderImage PathView StackLayout State PropertyChanges AnchorChanges StateGroup Instantiator DelegateModel
ObjectModel FocusScope FontMetrics TextMetrics SmoothedAnimation SpringAnimation ScriptAction PropertyAnimation
AnchorAnimation Scale Rotation PointHandler PinchHandler Window SystemPalette FolderListModel QsMenuAnchor
ClippingWrapperRectangle WrapperRectangle WrapperItem WrapperMouseArea ElapsedTimer HyprlandFocusGrab ListElement
SoundEffect MediaPlayer AudioOutput VideoOutput Video DesktopEntries PopupAnchor ColorQuantizer Retainable
PathAttribute PathPercent PathInterpolator Path RectangularShadow RotationAnimator OpacityAnimator ScaleAnimator XAnimator YAnimator
""".split())
# objects that aren't QQuickItems; a Behavior directly inside them crashes Qt 6.12
NON_ITEM = {"Singleton", "Scope", "ShellRoot", "PanelWindow", "FloatingWindow", "PopupWindow", "Variants", "LazyLoader",
            "QtObject", "WlSessionLock", "WlSessionLockSurface", "Popup", "OverlayPanel", "TrayMenu", "TrayTooltip"}
# types with no default property: a child object declared inside one fails to load
# JavaScript reserved and future-reserved words; QML rejects them as identifiers
RESERVED = set("""
break case catch class const continue debugger default delete do else enum export extends false finally for function
if implements import in instanceof interface let new null package private protected public return static super switch
this throw true try typeof var void while with yield abstract boolean byte char double final float goto int long
native short synchronized throws transient volatile
""".split())
NO_DEFAULT = {"Timer", "WheelHandler", "TapHandler", "HoverHandler", "DragHandler", "PointHandler", "PinchHandler",
              "NumberAnimation", "ColorAnimation", "PropertyAction", "PauseAnimation", "RotationAnimation", "FrameAnimation",
              "Process", "StdioCollector", "SplitParser", "Socket", "FontLoader", "SystemClock", "IdleMonitor"}
# shell files whose root object is one of those (and that don't add a default property)
for f in files:
    body = re.sub(r'(?m)^\s*(import|pragma)\b.*$|/\*.*?\*/|//[^\n]*', '', f.read_text(), flags=re.S)
    m = re.search(r'([A-Z]\w*)\s*\{', body)
    if m and m.group(1) in NO_DEFAULT and "default property" not in body:
        NO_DEFAULT.add(f.stem)

problems = 0


def report(f, msg):
    global problems
    problems += 1
    print(f"{f.relative_to(root)}: {msg}")


for f in files:
    src = f.read_text()
    # regex literals first (a `//` inside one isn't a comment)
    src_nore = re.sub(r'(?<=[(,=:!&|?])(\s*)/(?![/*])(?:\\.|\[(?:\\.|[^\]\n])*\]|[^/\\\n])+/[gimsuy]*', r'\1""', src)
    code = re.sub(r'`(?:\\.|[^`\\])*`|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|/\*.*?\*/|//[^\n]*', '""', src_nore, flags=re.S)
    line = lambda pos: code[:pos].count("\n") + 1

    for o, c in ("{}", "()", "[]"):
        if code.count(o) != code.count(c):
            report(f, f"unbalanced {o}{c} ({code.count(o)}/{code.count(c)})")

    inline = set(re.findall(r'\bcomponent\s+(\w+)\s*:', code))
    # folders this file can see: `import qs.A.B` and relative `import "Dir"`
    visible = {m.replace(".", "/") for m in re.findall(r'(?m)^import\s+qs\.([\w.]+)', src)}
    for rel in re.findall(r'(?m)^import\s+"([^"]+)"', src):
        visible.add((f.parent / rel).resolve().relative_to(root.resolve()).as_posix())
    for m in re.finditer(r'(?<![\w.])([A-Z]\w*)\s*\{', code):
        t = m.group(1)
        pre = code[max(0, m.start() - 20):m.start()]
        if re.search(r'\b(on|component|enum)\s+[\w.]*\s*$', pre):
            continue
        if t not in defined and t not in KNOWN and t not in inline:
            report(f, f"{line(m.start())}: unknown type {t}")
        elif t in homes and t not in inline:
            here = f.parent.relative_to(root).as_posix()
            if here not in homes[t] and not homes[t] & visible:
                report(f, f"{line(m.start())}: {t} is defined in {'/'.join(sorted(homes[t]))} but not imported")

    # new properties named like ones Qt's types already have (the file fails: "Cannot override
    # FINAL property", or the old one is silently shadowed)
    BUILTIN = {"x", "y", "z", "width", "height", "top", "bottom", "left", "right", "parent", "children", "visible",
               "opacity", "scale", "rotation", "anchors", "clip", "implicitWidth", "implicitHeight", "baseline",
               "transform", "antialiasing", "smooth"}
    # only inside visual objects: settings, services and the like don't have these
    NON_ITEM = {"JsonObject", "JsonAdapter", "Singleton", "QtObject", "Scope", "Variants", "Timer", "Process",
                "Connections", "IpcHandler", "FileView", "LazyLoader", "Component", "ShellRoot"}
    if not f.relative_to(root).as_posix().startswith("Compat/"):
        stack = []
        for m in re.finditer(r'([A-Z][\w.]*)\s*(?:on\s+[\w.]+\s*)?\{|\{|\}|\bproperty\s+[\w<>.]+\s+(\w+)', code):
            t = m.group(0)
            if m.group(2):
                if m.group(2) in BUILTIN and stack and stack[-1] not in NON_ITEM:
                    report(f, f"{line(m.start())}: a new property can't be called '{m.group(2)}' in {stack[-1]} (it already has one)")
            elif t == "}":
                if stack:
                    stack.pop()
            elif t == "{":
                stack.append(stack[-1] if stack else "")
            else:
                stack.append(m.group(1))

    # Variants and LazyLoader make one object: a second one inside fails the whole file
    # (it loads as nothing, so whatever it shows never appears)
    for m in re.finditer(r'(?<![\w.])(Variants|LazyLoader)\s*\{', code):
        depth, i, kids = 0, m.end() - 1, []
        while i < len(code):
            c = code[i]
            if c == "{":
                depth += 1
                if depth == 2:
                    head = code[max(0, i - 60):i]
                    t = re.search(r'([A-Z][\w.]*)\s*(?:on\s+[\w.]+\s*)?$', head)
                    pre = head[:t.start()] if t else ""
                    # an object, not a property's value (`foo: Bar {`), a handler or an inline component
                    if t and not re.search(r'(:|component\s+\w+\s*:)\s*$', pre):
                        kids.append((t.group(1), i))
            elif c == "}":
                depth -= 1
                if depth == 0:
                    break
            i += 1
        if len(kids) > 1:
            report(f, f"{line(kids[1][1])}: {m.group(1)} can hold one object, but {', '.join(k for k, _ in kids)} are inside it")

    # inline components can't see the ids of the file they're in: `root.x` inside one is
    # undefined at runtime (it loads fine and just doesn't work)
    for m in re.finditer(r'\bcomponent\s+(\w+)\s*:\s*[\w.]+\s*\{', code if not f.relative_to(root).as_posix().startswith("Compat/") else ""):
        start = m.end() - 1
        depth, i = 0, start
        while i < len(code):
            if code[i] == "{":
                depth += 1
            elif code[i] == "}":
                depth -= 1
                if depth == 0:
                    break
            i += 1
        block = code[start:i]
        outside = code[:m.start()] + code[i:]
        outer_ids = set(re.findall(r'\bid\s*:\s*(\w+)', outside))
        inner_ids = set(re.findall(r'\bid\s*:\s*(\w+)', block))
        props = set(re.findall(r'\bproperty\s+[\w<>.]+\s+(\w+)', block))
        for u in re.finditer(r'(?<![\w.])(\w+)\.', block):
            name = u.group(1)
            if name in outer_ids and name not in inner_ids and name not in props:
                report(f, f"{line(start + u.start())}: inline component {m.group(1)} uses '{name}', an id from outside it (not visible there)")
                break

    # JavaScript Quickshell's engine doesn't have (a TypeError at runtime)
    if not f.relative_to(root).as_posix().startswith("Compat/"):
        for m in re.finditer(r'Object\.fromEntries|\.flatMap\(|\.flat\(\)|\.replaceAll\(', code):
            report(f, f"{line(m.start())}: {m.group(0).strip('.(')} isn't in Quickshell's JavaScript")
    # reserved words QML refuses as names (the file then fails to load at all)
    for m in re.finditer(r'\b(?:property\s+[\w<>.]+|function|const|let|var|id\s*:)\s+(\w+)', code):
        if m.group(1) in RESERVED:
            report(f, f"{line(m.start())}: '{m.group(1)}' is a reserved word in QML and can't be used as a name")

    # the same handler or property set twice in one object (QML refuses the file)
    depth_keys = [set()]
    for m in re.finditer(r'(?m)\{|\}|^[ \t]*(on[A-Z]\w*|[a-z]\w*(?:\.[a-z]\w*)*)\s*:(?!:)', code):
        t = m.group(0)
        if t == "{":
            depth_keys.append(set())
        elif t == "}":
            if len(depth_keys) > 1:
                depth_keys.pop()
        else:
            k = m.group(1)
            if k in ("id",) or k.startswith("case") or k == "default":
                continue
            if k in depth_keys[-1] and k.startswith("on") and k[2:3].isupper():
                report(f, f"{line(m.start())}: {k} set twice in the same object")
            depth_keys[-1].add(k)

    readonly = set(re.findall(r'readonly property \S+ (\w+)', code))
    for m in re.finditer(r'Behavior on ([\w.]+)', code):
        if m.group(1) in readonly:
            report(f, f"{line(m.start())}: Behavior on readonly property '{m.group(1)}'")

    stack = []
    for m in re.finditer(r'([A-Z]\w*)\s*(?:on\s+[\w.]+\s*)?\{|\{|\}', code):
        tok = m.group(0)
        if tok == "}":
            if stack:
                stack.pop()
        elif tok == "{":
            stack.append(None)
        else:
            t = m.group(1)
            if t == "Behavior":
                owner = next((x for x in reversed(stack) if x), None)
                if owner in NON_ITEM:
                    report(f, f"{line(m.start())}: Behavior directly inside non-Item {owner}")
            # a bare `Type {` (not `prop: Type {` or inside a list) directly in its parent
            elif stack and stack[-1] in NO_DEFAULT and not re.search(r'[:\[,]\s*$', code[:m.start()]):
                report(f, f"{line(m.start())}: {t} declared inside {stack[-1]}, which has no default property")
            stack.append(t)

print(f"{len(files)} files checked, {problems} problem(s)")
sys.exit(1 if problems else 0)
