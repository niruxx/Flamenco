#!/usr/bin/env python3
"""Flamenco's translations.

  tools/i18n.py wrap       wraps the shell's display text in I18n.tr("…") (whole string
                           values of text / title / subtitle / label / placeholder / hint /
                           tip / description / t, and capitalized branches of ternaries on
                           those lines). Safe to run again: wrapped text is left alone.
  tools/i18n.py extract    every wrapped string → shell/assets/i18n/template.json
  tools/i18n.py check LANG how much of shell/assets/i18n/LANG.json is translated
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "shell"
KEYS = r"(?:text|title|subtitle|label|placeholder|hint|tip|description|t)"
SKIP = {"Commons/Settings.qml", "Commons/I18n.qml", "Commons/Palettes.qml"}
WHOLE = re.compile(r'((?<![\w.])' + KEYS + r'\s*:\s*)"((?:[^"\\]|\\.)*[A-Za-z](?:[^"\\]|\\.)*)"(?=\s*[;}\n,\]])')
TERN = re.compile(r'([?:]\s*)"([A-Z](?:[^"\\]|\\.)*)"')
LINEKEY = re.compile(r'(?<![\w.])' + KEYS + r'\s*:')
WRAPPED = re.compile(r'I18n\.tr\("((?:[^"\\]|\\.)*)"\)')


def files():
    for f in sorted(ROOT.rglob("*.qml")):
        rel = str(f.relative_to(ROOT))
        if "Compat/" in rel or rel in SKIP:
            continue
        yield f


def wrap() -> None:
    total = 0
    for f in files():
        s = f.read_text()
        out = []
        n = 0
        for line in s.split("\n"):
            if line.lstrip().startswith("//") or "I18n.tr(" in line and not WHOLE.search(line) and not TERN.search(line):
                out.append(line)
                continue
            new = WHOLE.sub(lambda m: m.group(1) + 'I18n.tr("' + m.group(2) + '")', line)
            if LINEKEY.search(new):
                # capitalized ternary branches, not already wrapped
                def tern(m):
                    start = m.start()
                    if new[max(0, start - 8):start].endswith("I18n.tr("):
                        return m.group(0)
                    return m.group(1) + 'I18n.tr("' + m.group(2) + '")'
                new = TERN.sub(tern, new)
            n += new != line
            out.append(new)
        if n:
            s2 = "\n".join(out)
            if "import qs.Commons" not in s2:
                s2 = re.sub(r"(import QtQuick\n)", r"\1import qs.Commons\n", s2, count=1)
            f.write_text(s2)
            total += n
    print(f"wrapped text on {total} lines")


def extract() -> dict:
    found = {}
    for f in files():
        for m in WRAPPED.finditer(f.read_text()):
            found[json.loads('"' + m.group(1) + '"')] = ""
    out = ROOT / "assets/i18n/template.json"
    out.write_text(json.dumps(dict(sorted(found.items())), ensure_ascii=False, indent=1) + "\n")
    print(f"{len(found)} strings → {out}")
    return found


def check(lang: str) -> None:
    want = {json.loads('"' + m.group(1) + '"') for f in files() for m in WRAPPED.finditer(f.read_text())}
    have = json.loads((ROOT / f"assets/i18n/{lang}.json").read_text())
    done = sum(1 for k in want if have.get(k))
    print(f"{lang}: {done} of {len(want)} translated ({done * 100 // max(1, len(want))}%)")


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "wrap":
        wrap()
    elif cmd == "extract":
        extract()
    elif cmd == "check" and len(sys.argv) > 2:
        check(sys.argv[2])
    else:
        print(__doc__)
