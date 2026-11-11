"""Night Shift's own sounds (the rest are Look Busy's, in audio/).
numpy + ffmpeg. Re-run after editing: python3 tools/make_audio.py"""
import os, subprocess, wave
import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "audio")
rng = np.random.default_rng(7)


def save_wav(name, x):
    x = np.clip(x, -1, 1)
    with wave.open(os.path.join(OUT, name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32000).astype(np.int16).tobytes())


def lowpass(x, k):
    y = np.zeros_like(x)
    a = 0.0
    for i in range(len(x)):
        a += k * (x[i] - a)
        y[i] = a
    return y


def seamless(x, sec):
    """Fold the last `sec` seconds over the start (equal-power crossfade) so
    the loop point can't be heard: play it on repeat and it never clicks."""
    n = int(SR * sec)
    body = x[n:].copy()
    k = np.linspace(0, 1, n)
    body[-n:] = body[-n:] * np.cos(k * np.pi / 2) + x[:n] * np.sin(k * np.pi / 2)
    return body


def t_of(sec):
    return np.arange(int(SR * sec)) / SR


# Text blip: a soft square chirp (pitched per speaker in the game).
t = t_of(0.045)
blip = np.sign(np.sin(2 * np.pi * 520 * t)) * np.exp(-t * 60) * 0.35
save_wav("blip.wav", blip)

# Copier: a mechanical whirr with a chunk at the start and a paper swish.
t = t_of(0.75)
whirr = np.sin(2 * np.pi * 110 * t + 3 * np.sin(2 * np.pi * 7 * t)) * 0.25
grain = lowpass(rng.standard_normal(len(t)), 0.15) * 0.5 * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 14 * t)))
env = np.minimum(1, t * 30) * np.minimum(1, (0.75 - t) * 8)
chunk = np.exp(-t * 40) * np.sin(2 * np.pi * 70 * t) * 0.7
save_wav("print.wav", (whirr + grain) * env + chunk)

# Thump: the lights dying (a deep boom with a relay click).
t = t_of(1.2)
boom = np.sin(2 * np.pi * (48 - 18 * t) * t) * np.exp(-t * 3.5) * 0.9
click = rng.standard_normal(len(t)) * np.exp(-t * 300) * 0.6
save_wav("thump.wav", boom + click)

# Night drone: 16 s loop. Two low detuned tones beating, a fridge-hum
# harmonic, filtered air, and a far-off minor third now and then.
dur = 16.0
t = t_of(dur)
loop = lambda f: np.sin(2 * np.pi * round(f * dur) / dur * t)
d = 0.32 * loop(55) + 0.28 * loop(55.5) + 0.08 * loop(110.25) + 0.05 * loop(165)
air = lowpass(rng.standard_normal(len(t)), 0.02) * 0.6
air *= 0.6 + 0.4 * np.sin(2 * np.pi * t / dur) ** 2
tones = np.zeros_like(t)
for start, f in [(2.0, 220.0), (6.5, 261.6), (11.0, 207.7)]:
    m = (t > start) & (t < start + 4)
    tt = t[m] - start
    tones[m] += np.sin(2 * np.pi * f * tt) * np.sin(np.pi * tt / 4) ** 2 * 0.06
x = (d + air + tones) * 0.8
x = seamless(np.concatenate([x, x[:int(SR * 3)]]), 3.0)
save_wav("_drone.wav", x)


# ---- soft psychedelic UI sounds: glassy, detuned, a little reversed.

def bell(f, dur, bright=2.0, decay=4.0):
    """An FM bell: a sine whose partials shimmer and fade."""
    t = t_of(dur)
    mod = np.sin(2 * np.pi * f * 1.414 * t) * bright * np.exp(-t * decay * 0.7)
    return np.sin(2 * np.pi * f * t + mod) * np.exp(-t * decay)


def chorus(x, cents=9, ms=11):
    """Two slightly detuned, slightly late copies: the woozy shimmer."""
    n = len(x)
    out = x.copy()
    for k, d in [(1, ms), (-1, ms * 1.7)]:
        rate = 2 ** (k * cents / 1200)
        idx = np.clip(np.arange(n) * rate, 0, n - 1)
        y = np.interp(idx, np.arange(n), x)
        shift = int(SR * d / 1000)
        y = np.concatenate([np.zeros(shift), y[:n - shift]])
        out += 0.6 * y
    return out / 2.2


def tail(x, sec=1.4, mix=0.35):
    """A cheap smeared reverb tail (a few decaying echoes, low-passed)."""
    n = len(x) + int(SR * sec)
    out = np.zeros(n)
    out[:len(x)] += x
    for i, d in enumerate([0.043, 0.071, 0.113, 0.167, 0.239, 0.331]):
        s0 = int(SR * d)
        out[s0:s0 + len(x)] += x * mix * (0.72 ** i)
    return lowpass(out, 0.35)


def pad(x, sec):
    return np.concatenate([x, np.zeros(int(SR * sec))])


# A choice picked: one glassy pluck, a fifth above whispering after it.
x = bell(660, 0.5, 1.2, 9) * 0.5
y = np.concatenate([np.zeros(int(SR * 0.035)), bell(990, 0.465, 0.8, 11) * 0.25])
x[:len(y)] += y[:len(x)]
save_wav("choice.wav", tail(chorus(x), 0.6, 0.25) * 0.8)

# Something got: a rising arpeggio of bells that blooms and drifts off.
notes = [523.25, 659.25, 783.99, 1046.5, 1318.5]
x = np.zeros(int(SR * 2.4))
for i, f in enumerate(notes):
    b = bell(f, 1.6, 1.6, 2.6) * (0.5 - i * 0.05)
    s0 = int(SR * i * 0.09)
    x[s0:s0 + len(b)] += b[:len(x) - s0]
save_wav("shimmer.wav", tail(chorus(x, 14, 15), 1.2, 0.3) * 0.6)

# A reverse swell: air and a soft chord breathing in (gliding to someone).
t = t_of(1.3)
chord = sum(np.sin(2 * np.pi * f * t) for f in [220, 277.18, 329.63, 440]) / 4
air = lowpass(rng.standard_normal(len(t)), 0.05) * 0.5
env = (t / t[-1]) ** 2.5
x = (chord * 0.5 + air) * env
x[-int(SR * 0.03):] *= np.linspace(1, 0, int(SR * 0.03))
save_wav("swell.wav", chorus(x, 12, 9) * 0.55)

# Tape stop: the world slowing down and dropping (the 3:33 blackout).
t = t_of(1.6)
speed = np.clip(1 - t / 1.6, 0, 1) ** 1.5
phase = np.cumsum(2 * np.pi * 180 * speed / SR)
x = (np.sin(phase) + 0.5 * np.sin(phase * 1.5) + 0.3 * np.sin(phase * 2.01)) * np.minimum(1, speed * 3) * 0.4
save_wav("tapestop.wav", tail(x, 0.8, 0.3))

# A wrong note: two bells a quarter-tone apart, beating (bad choices).
x = bell(415, 1.4, 2.5, 3) * 0.4 + bell(427, 1.4, 2.5, 3) * 0.4
save_wav("wrong.wav", tail(x, 1.0, 0.3) * 0.7)

# Page turn: a tiny airy tick.
t = t_of(0.12)
x = lowpass(rng.standard_normal(len(t)), 0.4) * np.exp(-t * 45) * 0.25 + bell(1760, 0.12, 0.5, 30) * 0.08
save_wav("page.wav", x)
subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", os.path.join(OUT, "_drone.wav"),
                "-c:a", "libvorbis", "-q:a", "3", os.path.join(OUT, "night_drone.ogg")], check=True)
os.remove(os.path.join(OUT, "_drone.wav"))
print("ok")
