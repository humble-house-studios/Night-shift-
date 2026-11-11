#!/usr/bin/env python3
"""The night's ambient score: Creative Commons tracks, fetched on the build
machine, trimmed and faded into loops, and credited in the game (CREDITS).

    python3 tools/fetch_score.py

Writes audio/score/<cue>.ogg and audio/score/credits.json. Each cue tries
its tracks in order and keeps the first that downloads and plays; if none
does, the game falls back to its own drone (audio/night_drone.ogg), so a
dead link never breaks the build. Needs curl and ffmpeg.
"""
import json
import os
import subprocess
import tempfile

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
}
MAX_SECONDS = 240


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
        if os.path.exists(out) and cue in credits and any(credits[cue]["url"] == t[3] for t in tracks):
            print("%s: kept %s" % (cue, credits[cue]["title"]))
            continue
        for title, author, lic, url, page in tracks:
            with tempfile.TemporaryDirectory() as d:
                raw = os.path.join(d, "raw")
                r = subprocess.run(["curl", "-sSfL", "--max-time", "180", "-A", "Mozilla/5.0 (humble-house-build)", "-o", raw, url])
                if r.returncode != 0 or duration(raw) < 30:
                    print("%s: %s didn't download" % (cue, title))
                    continue
                length = min(duration(raw), MAX_SECONDS)
                fade = "afade=t=in:d=4,afade=t=out:st=%.2f:d=6" % (length - 6)
                subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", raw, "-t", str(length), "-af", fade,
                                "-ar", "44100", "-ac", "2", "-c:a", "libvorbis", "-q:a", "3", out], check=True)
                credits[cue] = {"title": title, "author": author, "license": lic, "url": url, "page": page}
                print("%s: %s by %s (%.0f s)" % (cue, title, author, length))
                break
    json.dump(credits, open(credits_file, "w"), indent=1)
    print("score: " + ", ".join("%s=%s" % (c, credits[c]["title"]) for c in credits))


if __name__ == "__main__":
    main()
