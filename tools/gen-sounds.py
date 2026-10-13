#!/usr/bin/env python3
"""Synthesize the bundled "Flamenco" sound theme into data/sounds/flamenco.

The theme is small soft chimes and clicks, so the shell has event sounds even
when no other sound theme is installed. Re-run after tweaking a sound:

    python3 tools/gen-sounds.py
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parent.parent / "data/sounds/flamenco"


def note(freq, dur, start=0.0, vol=0.5, decay=6.0, partials=((1, 1.0), (2, 0.18), (3, 0.06))):
    """A plucked/bell-ish tone: a few partials under an exponential decay."""
    return (start, dur, lambda t: vol * math.exp(-decay * t) * min(1.0, t / 0.004)
            * sum(a * math.sin(2 * math.pi * freq * m * t) for m, a in partials))


def noise(dur, start=0.0, vol=0.4, decay=40.0):
    rnd = random.Random(7)
    return (start, dur, lambda t: vol * math.exp(-decay * t) * (rnd.random() * 2 - 1))


def render(name, parts, tail=0.05):
    length = max(s + d for s, d, _ in parts) + tail
    buf = [0.0] * int(length * RATE)
    for start, dur, fn in parts:
        s = int(start * RATE)
        for i in range(int(dur * RATE)):
            t = i / RATE
            # short fade-out so nothing clicks at the end
            fade = min(1.0, (dur - t) / 0.02)
            buf[s + i] += fn(t) * fade
    peak = max(1e-9, max(abs(x) for x in buf))
    gain = min(1.0, 0.7 / peak)
    path = OUT / "stereo" / f"{name}.wav"
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, x * gain)) * 32767)) for x in buf))


C5, E5, G5, A5, B5 = 523.25, 659.25, 783.99, 880.0, 987.77
C6, D6, E6, G6, A6 = 1046.5, 1174.66, 1318.51, 1567.98, 1760.0
BELL = ((1, 1.0), (2.76, 0.35), (5.4, 0.15), (8.93, 0.06))

SOUNDS = {
    # notifications
    "message-new-instant": [note(E6, 0.35, 0.0, decay=9), note(A6, 0.45, 0.09, decay=8)],
    "message": [note(C6, 0.35, 0.0, decay=9), note(G6, 0.45, 0.09, decay=8)],
    "dialog-information": [note(A5, 0.5, decay=7)],
    "dialog-warning": [note(A6, 0.3, 0.0, decay=10), note(E6, 0.5, 0.12, decay=7)],
    "dialog-error": [note(E5, 0.3, 0.0, decay=9), note(C5, 0.6, 0.13, decay=6)],
    "complete": [note(C6, 0.3, 0.0, decay=10), note(E6, 0.3, 0.08, decay=10), note(G6, 0.5, 0.16, decay=7)],
    "bell": [note(A5, 0.9, decay=4.5, partials=BELL)],
    # feedback ticks
    "audio-volume-change": [note(D6, 0.07, decay=55, partials=((1, 1.0), (2, 0.3)))],
    "brightness-change": [note(G6, 0.06, decay=60, partials=((1, 1.0), (2, 0.25)))],
    "button-pressed": [note(C6, 0.04, decay=80, partials=((1, 1.0),))],
    # screenshots
    "screen-capture": [noise(0.05, 0.0, decay=60), noise(0.07, 0.07, decay=45)],
    "camera-shutter": [noise(0.05, 0.0, decay=60), noise(0.07, 0.07, decay=45)],
    # hardware
    "device-added": [note(G5, 0.25, 0.0, decay=12), note(C6, 0.35, 0.08, decay=10)],
    "device-removed": [note(C6, 0.25, 0.0, decay=12), note(G5, 0.35, 0.08, decay=10)],
    "power-plug": [note(E5, 0.25, 0.0, decay=12), note(B5, 0.35, 0.08, decay=10)],
    "power-unplug": [note(B5, 0.25, 0.0, decay=12), note(E5, 0.35, 0.08, decay=10)],
    "battery-low": [note(E6, 0.25, 0.0, decay=10), note(E6, 0.35, 0.18, decay=9)],
    # session
    "service-login": [note(f, 0.7, i * 0.07, vol=0.35, decay=4) for i, f in enumerate((C5, E5, G5, C6))],
    "service-logout": [note(f, 0.7, i * 0.07, vol=0.35, decay=4) for i, f in enumerate((C6, G5, E5, C5))],
    "desktop-login": [note(f, 0.7, i * 0.07, vol=0.35, decay=4) for i, f in enumerate((C5, E5, G5, C6))],
    "desktop-logout": [note(f, 0.7, i * 0.07, vol=0.35, decay=4) for i, f in enumerate((C6, G5, E5, C5))],
}

INDEX = """[Sound Theme]
Name=Flamenco
Comment=Soft chimes and clicks bundled with Flamenco Shell
Inherits=freedesktop
Directories=stereo

[stereo]
OutputProfile=stereo
"""

if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "index.theme").write_text(INDEX)
    for name, parts in SOUNDS.items():
        render(name, parts)
    print(f"wrote {len(SOUNDS)} sounds to {OUT}")
