#!/usr/bin/env python3
"""'Clock Out (Heaven Mix)': the dream-pop trance track for the wheat field
and the credits. Original, made from scratch here (numpy + scipy + ffmpeg):
124 BPM in F# minor / A major, vi-IV-I-V, supersaw pads that breathe with a
sidechain, a 16th-note pluck arp in ping-pong delay, rolling offbeat bass,
a wordless "aah" lead, and a big soft reverb over everything.

    python3 tools/make_heaven.py      -> audio/heaven.ogg
"""
import os
import subprocess
import tempfile
import wave

import numpy as np
from scipy.signal import butter, fftconvolve, sosfilt

SR = 44100
BPM = 124.0
BEAT = 60.0 / BPM
BAR = BEAT * 4
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "audio")
rng = np.random.default_rng(124)

# Sections in bars: intro, build, drop, break, drop, outro.
SECTIONS = [("intro", 8), ("build", 8), ("drop", 16), ("break", 8), ("drop", 16), ("outro", 8)]
BARS = sum(n for _, n in SECTIONS)
N = int(SR * BAR * BARS) + SR * 4
t_all = np.arange(N) / SR


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)


# vi - IV - I - V in A major: F#m, D, A, E (root midi notes, chord tones).
CHORDS = [[42, 54, 57, 61], [38, 54, 57, 62], [45, 57, 61, 64], [40, 56, 59, 64]]
# The lead: two notes a bar, singable.
MELODY = [[73, 69], [74, 78], [76, 73], [71, 68]]


def section_at(bar):
    b = 0
    for name, n in SECTIONS:
        if bar < b + n:
            return name, (bar - b) / n
        b += n
    return "end", 1.0


def lp(x, f, order=2):
    return sosfilt(butter(order, f, "low", fs=SR, output="sos"), x)


def hp(x, f, order=2):
    return sosfilt(butter(order, f, "high", fs=SR, output="sos"), x)


def bp(x, lo, hi, order=2):
    return sosfilt(butter(order, [lo, hi], "band", fs=SR, output="sos"), x)


def saw(f, t, phase=0.0):
    return 2.0 * ((f * t + phase) % 1.0) - 1.0


def place(buf, start, x):
    s = int(start * SR)
    e = min(len(buf), s + len(x))
    if e > s:
        buf[s:e] += x[:e - s]


L = np.zeros(N)
R = np.zeros(N)
pad_dark = np.zeros((2, N))
pad_bright = np.zeros((2, N))
duck = np.ones(N)
bright_curve = np.zeros(N)
drums = np.zeros(N)
bass = np.zeros(N)
arp = np.zeros(N)
lead = np.zeros(N)
kick_on = np.zeros(BARS, bool)

for bar in range(BARS):
    name, k = section_at(bar)
    chord = CHORDS[bar % 4]
    t0 = bar * BAR
    seg = np.arange(int(BAR * SR)) / SR
    # Supersaw pad: seven detuned saws per note, spread left/right.
    pad = np.zeros((2, len(seg)))
    for n in chord[1:] + [chord[1] + 12]:
        for v in range(7):
            det = (v - 3) * 0.0011
            ph = rng.random()
            s = saw(midi(n) * (1 + det), seg, ph) * 0.05
            pan = (v - 3) / 3.0
            pad[0] += s * (1 - pan) * 0.5 + s * 0.25
            pad[1] += s * (1 + pan) * 0.5 + s * 0.25
    env = np.minimum(1, seg / 0.05) * np.minimum(1, (BAR - seg) / 0.08)
    pad *= env
    s0 = int(t0 * SR)
    pad_dark[:, s0:s0 + len(seg)] += pad
    # How open the pad filter is through each section.
    open_ = {"intro": 0.1 + 0.15 * k, "build": 0.25 + 0.6 * k, "drop": 1.0, "break": 0.35, "outro": 0.8 - 0.7 * k}.get(name, 0.0)
    bright_curve[s0:s0 + len(seg)] = open_
    drop = name == "drop"
    kick_on[bar] = drop or (name == "build" and k >= 0.5) or (name == "outro" and k < 0.5)
    for beat in range(4):
        tb = t0 + beat * BEAT
        if kick_on[bar]:
            kt = np.arange(int(0.35 * SR)) / SR
            f = 48 + 90 * np.exp(-kt * 30)
            kick = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-kt * 9) * 0.95
            kick[:60] += rng.standard_normal(60) * 0.3
            place(drums, tb, kick)
            # Sidechain: everything ducks under the kick and swells back.
            d = 1 - 0.65 * np.exp(-np.arange(int(BEAT * SR)) / SR * 9)
            s1 = int(tb * SR)
            duck[s1:s1 + len(d)] = np.minimum(duck[s1:s1 + len(d)], d[:max(0, min(len(d), N - s1))])
        if drop or name == "build":
            # Offbeat hats (and in the drops a soft clap on 2 and 4).
            ht = np.arange(int(0.06 * SR)) / SR
            hat = rng.standard_normal(len(ht)) * np.exp(-ht * 70) * (0.12 if drop else 0.06 * k)
            place(drums, tb + BEAT / 2, hp(hat, 7000))
            if drop and beat in (1, 3):
                ct = np.arange(int(0.25 * SR)) / SR
                clap = bp(rng.standard_normal(len(ct)), 900, 2600) * np.exp(-ct * 18) * 0.35
                place(drums, tb, clap)
        if drop:
            # Rolling offbeat bass on the root.
            bt = np.arange(int(BEAT / 2 * 0.9 * SR)) / SR
            f = midi(chord[0] + 12)
            b = (saw(f, bt) * 0.6 + np.sin(2 * np.pi * f / 2 * bt) * 0.5) * np.exp(-bt * 6) * 0.5
            place(bass, tb + BEAT / 2, b)
    # The pluck arp: 16ths up and down the chord, in every section but the intro's start.
    if not (name == "intro" and k < 0.5):
        pattern = [chord[1], chord[2], chord[3], chord[1] + 12, chord[3], chord[2] + 12, chord[3] + 12, chord[2] + 12]
        level = {"intro": 0.10, "build": 0.14, "drop": 0.16, "break": 0.13, "outro": 0.12}.get(name, 0.1)
        for i in range(16):
            n = pattern[i % len(pattern)] + 12
            at = np.arange(int(0.22 * SR)) / SR
            f = midi(n)
            pl = (np.sin(2 * np.pi * f * at) + 0.35 * saw(f, at)) * np.exp(-at * 16) * level
            place(arp, t0 + i * BEAT / 4, pl)
    # The wordless lead in the drops and the break.
    if name in ("drop", "break"):
        for j, n in enumerate(MELODY[bar % 4]):
            dur = BAR / 2 * 0.96
            lt = np.arange(int(dur * SR)) / SR
            f = midi(n) * (1 + 0.006 * np.sin(2 * np.pi * 5.2 * lt) * np.minimum(1, lt / 0.4))
            ph = np.cumsum(f) / SR
            src = 2 * (ph % 1.0) - 1
            # "aah": two formant bands over a buzzy source.
            v = bp(src, 650, 1100) * 1.0 + bp(src, 1050, 1400) * 0.6 + bp(src, 2400, 2900) * 0.25
            v *= np.minimum(1, lt / 0.12) * np.minimum(1, (dur - lt) / 0.25) * (0.28 if name == "drop" else 0.22)
            place(lead, t0 + j * BAR / 2, v)

# The filter sweep on the pads: dark and bright versions crossfaded.
for ch in range(2):
    pad_bright[ch] = lp(pad_dark[ch], 5200)
    pad_dark[ch] = lp(pad_dark[ch], 700)
c = lp(bright_curve, 3)
pads = pad_dark * (1 - c) + pad_bright * c

# A riser into each drop: rising filtered noise.
for bar in range(BARS):
    name, k = section_at(bar)
    if name == "build" and abs(k - 0.5) < 1e-6:
        dur = BAR * 4
        rt = np.arange(int(dur * SR)) / SR
        noise = rng.standard_normal(len(rt))
        riser = np.zeros_like(noise)
        for i in range(8):
            a, b = int(len(rt) * i / 8), int(len(rt) * (i + 1) / 8)
            riser[a:b] = bp(noise[a:b], 400 + 900 * i, 1400 + 1300 * i)
        riser *= (rt / dur) ** 2 * 0.25
        place(arp, bar * BAR, riser)

# Ping-pong delay on the arp (3/16), dotted and wide.
dl = int(BEAT * 0.75 * SR)
arpL, arpR = arp.copy(), arp.copy() * 0.6
for i in range(1, 6):
    g = 0.42 ** i
    sh = dl * i
    tgt = arpL if i % 2 == 0 else arpR
    tgt[sh:] += arp[:-sh] * g

# Mix: pads, arp, lead into the reverb; drums and bass dry-ish.
L = pads[0] * 0.9 + arpL + lead * 0.9
R = pads[1] * 0.9 + arpR + lead * 0.9
ir_t = np.arange(int(3.2 * SR)) / SR
ir_env = np.exp(-ir_t * 1.6)
irL = rng.standard_normal(len(ir_t)) * ir_env
irR = rng.standard_normal(len(ir_t)) * ir_env
irL[:int(0.02 * SR)] = 0
irR[:int(0.027 * SR)] = 0
irL, irR = lp(irL, 6000) / 40, lp(irR, 6000) / 40
wetL = fftconvolve(hp(L, 200), irL)[:N]
wetR = fftconvolve(hp(R, 200), irR)[:N]
L = (L * 0.75 + wetL * 0.9) * duck + drums + bass * duck ** 0.5
R = (R * 0.75 + wetR * 0.9) * duck + drums + bass * duck ** 0.5

# Fade the very end, soft-clip, normalise.
total = BAR * BARS + 3.0
end = int(total * SR)
L, R = L[:end], R[:end]
fade = np.minimum(1, (total - np.arange(end) / SR) / 6.0)
L *= fade
R *= fade
mx = max(np.abs(L).max(), np.abs(R).max())
L, R = np.tanh(L / mx * 1.4) / np.tanh(1.4), np.tanh(R / mx * 1.4) / np.tanh(1.4)
st = np.stack([L, R], 1) * 0.89

with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
    w = wave.open(tmp.name, "wb")
    w.setnchannels(2)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes((st * 32000).astype(np.int16).tobytes())
    w.close()
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp.name, "-c:a", "libvorbis", "-q:a", "5",
                    os.path.join(OUT, "heaven.ogg")], check=True)
    os.remove(tmp.name)
print("heaven.ogg: %.0f s" % total)
