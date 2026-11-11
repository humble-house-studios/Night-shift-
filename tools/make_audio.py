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
fade = int(SR * 0.05)
x[:fade] *= np.linspace(0, 1, fade) ** 0.5 * 0 + 1
save_wav("_drone.wav", x)
subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", os.path.join(OUT, "_drone.wav"),
                "-c:a", "libvorbis", "-q:a", "3", os.path.join(OUT, "night_drone.ogg")], check=True)
os.remove(os.path.join(OUT, "_drone.wav"))
print("ok")
