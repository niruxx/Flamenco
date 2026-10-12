#!/usr/bin/env python3
"""Static sanity checks for the shell's QML (no Qt needed).

Catches the load-time errors we've actually hit:
  - unbalanced braces / parens / brackets
  - object types that aren't defined in the shell or a known module
  - `Behavior on` a readonly property            (QML refuses to load)
  - `Behavior` attached to a non-Item object      (Qt 6.12 segfaults)

usage: tools/qmlcheck.py [shell-dir]
"""
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else pathlib.Path(__file__).resolve().parent.parent / "shell")
files = sorted(root.rglob("*.qml"))
defined = {f.stem for f in files}

KNOWN = set("""
Item Rectangle Text TextInput TextEdit Image Row Column Flow Grid Repeater Loader MouseArea Timer Behavior
NumberAnimation ColorAnimation SequentialAnimation ParallelAnimation PauseAnimation PropertyAction RotationAnimation
Transition Connections Component QtObject Binding Gradient GradientStop Translate ListView GridView Flickable ListModel
HoverHandler DragHandler WheelHandler TapHandler FontLoader MultiEffect RowLayout ColumnLayout GridLayout
ShellRoot Scope Variants PanelWindow FloatingWindow PopupWindow LazyLoader Singleton SystemClock Process StdioCollector
SplitParser FileView JsonAdapter JsonObject IpcHandler Region PwObjectTracker NotificationServer WlSessionLock
WlSessionLockSurface PamContext IdleMonitor ClippingRectangle IconImage QsMenuOpener Shortcut
""".split())
# objects that aren't QQuickItems; a Behavior directly inside them crashes Qt 6.12
NON_ITEM = {"Singleton", "Scope", "ShellRoot", "PanelWindow", "FloatingWindow", "PopupWindow", "Variants", "LazyLoader",
            "QtObject", "WlSessionLock", "WlSessionLockSurface", "Popup", "OverlayPanel", "TrayMenu", "TrayTooltip"}

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
    for m in re.finditer(r'(?<![\w.])([A-Z]\w*)\s*\{', code):
        t = m.group(1)
        pre = code[max(0, m.start() - 20):m.start()]
        if re.search(r'\b(on|component)\s+[\w.]*\s*$', pre):
            continue
        if t not in defined and t not in KNOWN and t not in inline:
            report(f, f"{line(m.start())}: unknown type {t}")

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
            stack.append(t)

print(f"{len(files)} files checked, {problems} problem(s)")
sys.exit(1 if problems else 0)
