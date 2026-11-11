#!/usr/bin/env python3
"""The night's ambient score: Creative Commons tracks, fetched on the build
machine, trimmed and faded into loops, and credited in the game (CREDITS).

    python3 tools/fetch_score.py

Writes audio/score/<cue>.ogg and audio/score/credits.json. Each track is
made into a seamless loop: its last seconds are folded over its start with
an equal-power crossfade, so it repeats with no gap, dip or click. Each cue tries
its tracks in order and keeps the first that downloads and plays; if none
does, the game falls back to its own drone (audio/night_drone.ogg), so a
dead link never breaks the build. Needs curl and ffmpeg.
"""
import json
import os
import subprocess
import tempfile

import numpy as np

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
OUT = os.path.join(ROOT, "audio", "score")
KEVIN = "https://incompetech.com/music/royalty-free/mp3-royaltyfree/"
CC_BY = "CC BY 4.0"

# cue: [(title, author, license, url, source page)]
CUES = {
    # The title sequence: the sun going down over the bay.
    "title": [
        ("Dreamer", "Kevin MacLeod", CC_BY, KEVIN + "Dreamer.mp3", "https://incompetech.com"),
        ("Meditation Impromptu 02", "Kevin MacLeod", CC_BY, KEVIN + "Meditation%20Impromptu%2002.mp3", "https://incompetech.com"),
    ],
    # 11:58 PM to 3:33 AM: quiet, wrong, a long held breath.
    "night": [
        ("Long Note Four", "Kevin MacLeod", CC_BY, KEVIN + "Long%20Note%20Four.mp3", "https://incompetech.com"),
        ("Long Note Two", "Kevin MacLeod", CC_BY, KEVIN + "Long%20Note%20Two.mp3", "https://incompetech.com"),
    ],
    # After the blackout: the building is awake.
    "late": [
        ("Dark Ambient Drone", "Tsorthan Grove", CC_BY,
         "https://opengameart.org/sites/default/files/dark_ambient_drone_loop.flac", "https://opengameart.org/content/dark-ambient-drone"),
        ("Lightless Dawn", "Kevin MacLeod", CC_BY, KEVIN + "Lightless%20Dawn.mp3", "https://incompetech.com"),
    ],
    # The wheat field and the credits: dreamy synthwave/trance that opens up.
    # Not looped: it plays once, start to finish, under the roll.
    "field": [
        ("Dreamstate", "Bogart VGM", "CC BY 3.0",
         "https://opengameart.org/sites/default/files/Dreamstate.mp3", "https://opengameart.org/content/dreamstate-synthwave"),
        ("Floating Cities", "Kevin MacLeod", CC_BY, KEVIN + "Floating%20Cities.mp3", "https://incompetech.com"),
    ],
}
ONCE = {"field"}
MAX_SECONDS = 240
FOLD = 8.0
PROCESS = 2  # bump to remake every loop


def duration(path):
    r = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", path],
                       capture_output=True, text=True)
    try:
        return float(r.stdout.strip())
    except ValueError:
        return 0.0


def main():
    os.makedirs(OUT, exist_ok=True)
    credits_file = os.path.join(OUT, "credits.json")
    credits = json.load(open(credits_file)) if os.path.exists(credits_file) else {}
    for cue, tracks in CUES.items():
        out = os.path.join(OUT, cue + ".ogg")
        if os.path.exists(out) and cue in credits and credits[cue].get("process") == PROCESS and any(credits[cue]["url"] == t[3] for t in tracks):
            print("%s: kept %s" % (cue, credits[cue]["title"]))
            continue
        for title, author, lic, url, page in tracks:
            with tempfile.TemporaryDirectory() as d:
                raw = os.path.join(d, "raw")
                r = subprocess.run(["curl", "-sSfL", "--max-time", "180", "-A", "Mozilla/5.0 (humble-house-build)", "-o", raw, url])
                if r.returncode != 0 or duration(raw) < 30:
                    print("%s: %s didn't download" % (cue, title))
                    continue
                if cue in ONCE:
                    length = min(duration(raw), 330.0)
                    fade = "afade=t=in:d=1.5,afade=t=out:st=%.2f:d=6,loudnorm=I=-16:TP=-1.5:LRA=11" % (length - 6)
                    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", raw, "-t", str(length), "-af", fade,
                                    "-ar", "44100", "-ac", "2", "-c:a", "libvorbis", "-q:a", "4", out], check=True)
                    credits[cue] = {"title": title, "author": author, "license": lic, "url": url, "page": page, "process": PROCESS}
                    print("%s: %s by %s (%.0f s)" % (cue, title, author, length))
                    break
                length = min(duration(raw), MAX_SECONDS + FOLD)
                pcm = os.path.join(d, "pcm.raw")
                subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", raw, "-t", str(length), "-f", "f32le",
                                "-ar", "44100", "-ac", "2", pcm], check=True)
                x = np.fromfile(pcm, dtype=np.float32).reshape(-1, 2)
                n = int(44100 * FOLD)
                body = x[n:].copy()
                k = np.linspace(0, 1, n)[:, None]
                body[-n:] = body[-n:] * np.cos(k * np.pi / 2) + x[:n] * np.sin(k * np.pi / 2)
                body.astype(np.float32).tofile(pcm)
                subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-f", "f32le", "-ar", "44100", "-ac", "2", "-i", pcm,
                                "-af", "loudnorm=I=-20:TP=-2:LRA=9", "-ar", "44100", "-c:a", "libvorbis", "-q:a", "3", out], check=True)
                credits[cue] = {"title": title, "author": author, "license": lic, "url": url, "page": page, "process": PROCESS}
                print("%s: %s by %s (%.0f s)" % (cue, title, author, length))
                break
    json.dump(credits, open(credits_file, "w"), indent=1)
    print("score: " + ", ".join("%s=%s" % (c, credits[c]["title"]) for c in credits))


if __name__ == "__main__":
    main()
