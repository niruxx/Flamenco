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
SplitParser FileView JsonAdapter JsonObject IpcHandler Region PwObjectTracker NotificationServer WlSessionLock
WlSessionLockSurface PamContext IdleMonitor ClippingRectangle IconImage QsMenuOpener Shortcut ScriptModel PersistentProperties Socket
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
    code = re.sub(r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|/\*.*?\*/|//[^\n]*', '""', src, flags=re.S)
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
        if re.search(r'\b(on|component)\s+[\w.]*\s*$', pre):
            continue
        if t not in defined and t not in KNOWN and t not in inline:
            report(f, f"{line(m.start())}: unknown type {t}")
        elif t in homes and t not in inline:
            here = f.parent.relative_to(root).as_posix()
            if here not in homes[t] and not homes[t] & visible:
                report(f, f"{line(m.start())}: {t} is defined in {'/'.join(sorted(homes[t]))} but not imported")

    # reserved words QML refuses as names (the file then fails to load at all)
    for m in re.finditer(r'\b(?:property\s+[\w<>.]+|function|const|let|var|id\s*:)\s+(\w+)', code):
        if m.group(1) in RESERVED:
            report(f, f"{line(m.start())}: '{m.group(1)}' is a reserved word in QML and can't be used as a name")

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
