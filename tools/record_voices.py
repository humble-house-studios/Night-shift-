#!/usr/bin/env python3
"""Records every line of Night Shift with Kokoro, a free open-source neural
voice that runs on the build machine itself: no API keys, no daily limits,
no credits. Each character gets their own Kokoro voice (and a little studio
treatment: the Night Manager comes through a phone, Printy is a printer).

    pip install kokoro-onnx soundfile
    python3 tools/record_voices.py <model dir>

Reads data/voice_lines.json (tools/export_lines.gd writes it from the
script) and writes audio/voice/<file>.ogg, the name main.gd looks each page
up by. Lines already recorded are kept (CI caches the folder), so only new
or changed lines get recorded; clips no longer in the script are removed.
Bump VERSION to re-record everything (after changing a voice).
Needs ffmpeg.
"""
import json
import os
import re
import subprocess
import sys
import tempfile
import time

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
OUT = os.path.join(ROOT, "audio", "voice")
VERSION = "1"

# who: (kokoro voice or [(voice, weight), ...], speed, lang, ffmpeg filter)
PHONE = "highpass=f=280,lowpass=f=3600,acrusher=bits=12:mix=0.2"
CAST = {
    # A British storyteller for the narration: calm, a little eerie.
    "narr": ("bf_emma", 0.95, "en-gb", ""),
    "you": ("am_eric", 1.0, "en-us", ""),
    # Warm, a bit tired, a dad.
    "dale": ("am_michael", 0.94, "en-us", ""),
    # Deadpan, slow, seen it all: a touch lower.
    "wendy": ([("af_sarah", 0.6), ("af_nicole", 0.4)], 0.88, "en-us", "asetrate=24000*0.93,aresample=24000,atempo=1.075"),
    # Bright, fast, a lot of caffeine.
    "kip": ("am_puck", 1.12, "en-us", ""),
    # A copier with feelings: robot-ish but clear.
    "printy": ("am_echo", 0.98, "en-us", "asetrate=24000*1.08,aresample=24000,atempo=0.926,acrusher=bits=7:mode=log:mix=0.3,flanger=delay=1:depth=1.5:speed=6"),
    # Smooth, polite, wrong: lower, down a phone line, with a long tail.
    "manager": ("am_fenrir", 0.9, "en-us", "asetrate=24000*0.88,aresample=24000,atempo=1.136," + PHONE + ",aecho=0.8:0.6:60|140:0.3|0.18"),
    # A whispering coffee maker.
    "coffee": ("af_nicole", 0.85, "en-us", "asetrate=24000*0.82,aresample=24000,atempo=1.22,aecho=0.8:0.7:50:0.35"),
}

SMALL = {"one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
         "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen",
         "eighteen", "nineteen"}
TENS = {2: "twenty", 3: "thirty", 4: "forty", 5: "fifty"}
ONES = ["", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
        "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"]


def minutes(m):
    if m == 0:
        return "o'clock"
    if m < 10:
        return "oh " + ONES[m]
    if m < 20:
        return ONES[m]
    return TENS[m // 10] + ("" if m % 10 == 0 else "-" + ONES[m % 10])


def speakable(who, text):
    """The words to say for a page (the screen keeps the original)."""
    t = text
    t = t.replace("PRINTY-9000", "Printy nine thousand").replace("#1 DAD", "number one dad")
    t = t.replace("0-6-0-0", "zero, six, zero, zero").replace("0600", "zero six hundred")
    t = re.sub(r"\b(\d{1,2}):(\d\d)\s*(AM|PM)\b", lambda m: "%s %s %s" % (ONES[int(m.group(1))], minutes(int(m.group(2))), " ".join(m.group(3))), t)
    t = re.sub(r"\b(\d{1,2}):(\d\d)\b", lambda m: "%s %s" % (ONES[int(m.group(1))], minutes(int(m.group(2)))), t)
    t = re.sub(r"(?<![\w])-(\d+)", r"minus \1", t)
    t = t.replace("'09", "oh-nine").replace("D. PRUITT", "D. Pruitt")
    t = t.replace("K-I-P", "K. I. P.").replace("\"KIP\"", "Kip")
    # Shouty capitals (Printy, screens) read as ordinary words.
    t = re.sub(r"\b[A-Z][A-Z']+\b", lambda m: m.group(0) if m.group(0) in ("IP", "QA") else m.group(0).lower(), t)
    t = re.sub(r"\bi\b", "I", t)
    t = re.sub(r"(^|[.!?]\s+)([a-z])", lambda m: m.group(1) + m.group(2).upper(), t)
    t = t.replace("...", "…").replace("\"", "")
    return t.strip()


def main():
    model_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    import numpy as np
    import soundfile as sf
    from kokoro_onnx import Kokoro

    kokoro = Kokoro(os.path.join(model_dir, "kokoro-v1.0.onnx"), os.path.join(model_dir, "voices-v1.0.bin"))
    lines = json.load(open(os.path.join(ROOT, "data", "voice_lines.json")))
    os.makedirs(OUT, exist_ok=True)
    stamp_file = os.path.join(OUT, "VERSION")
    if not os.path.exists(stamp_file) or open(stamp_file).read().strip() != VERSION:
        for f in os.listdir(OUT):
            os.remove(os.path.join(OUT, f))
        open(stamp_file, "w").write(VERSION)
    wanted = {l["file"] + ".ogg" for l in lines}
    for f in os.listdir(OUT):
        if f.endswith(".ogg") and f not in wanted:
            os.remove(os.path.join(OUT, f))
    styles = {}

    def style(v):
        if isinstance(v, str):
            return v
        key = json.dumps(v)
        if key not in styles:
            styles[key] = sum(kokoro.get_voice_style(name) * w for name, w in v)
        return styles[key]

    made, kept, failed, t0 = 0, 0, 0, time.time()
    for l in lines:
        path = os.path.join(OUT, l["file"] + ".ogg")
        if os.path.exists(path):
            kept += 1
            continue
        voice, speed, lang, fx = CAST.get(l["who"], CAST["narr"])
        text = speakable(l["who"], l["text"])
        if not re.search(r"[A-Za-z]", text):
            continue
        try:
            samples, rate = kokoro.create(text, voice=style(voice), speed=speed, lang=lang)
            samples = np.concatenate([np.zeros(int(rate * 0.06)), samples, np.zeros(int(rate * 0.15))])
            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
                sf.write(tmp.name, samples, rate)
            chain = ",".join(f for f in [fx, "loudnorm=I=-17:TP=-1.5:LRA=11"] if f)
            subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", tmp.name, "-af", chain, "-ar", "24000", "-ac", "1",
                            "-c:a", "libvorbis", "-q:a", "3", path], check=True)
            os.remove(tmp.name)
            made += 1
        except Exception as e:  # one bad line shouldn't stop the rest
            failed += 1
            print("failed %s (%s): %s" % (l["file"], l["who"], e))
    size = sum(os.path.getsize(os.path.join(OUT, f)) for f in os.listdir(OUT))
    print("recorded %d, kept %d, failed %d, %.1f MB, %.0f s" % (made, kept, failed, size / 1e6, time.time() - t0))


if __name__ == "__main__":
    main()
