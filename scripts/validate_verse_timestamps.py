#!/usr/bin/env python3
"""Validate the audio verse markers in GospelForIpad/VerseTimestamps.swift.

The verse-marked audio is first-class data: the timestamps drive the "karaoke"
highlight, today's-reading playback start, and verse navigation. This script
re-checks the invariants that the 2026-07-08 audio verification established.

Structural checks (always run):
  1. verse 1 of every chapter is 0
  2. timestamps are strictly increasing within a chapter
  3. verse count equals the CBCK text (GospelText.json) for every chapter

Audio checks (run when PyAV is installed and AudioFiles/ is present):
  4. the last verse marker lies inside the audio duration
  5. every marker (verse >= 2) is within TOLERANCE of a speech onset that
     follows a >= 300 ms pause (monotonic DP alignment)

Run:  python3 scripts/validate_verse_timestamps.py [--audio]
Exit code 0 = all good; 1 = violations (printed).
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SWIFT = os.path.join(ROOT, "GospelForIpad", "VerseTimestamps.swift")
TEXT = os.path.join(ROOT, "GospelForIpad", "GospelText.json")
AUDIO_ROOT = os.path.join(ROOT, "GospelForIpad", "AudioFiles")

BOOKS = ["matthew", "mark", "luke", "john"]
FOLDER = {"matthew": "01.마태오복음", "mark": "02.마르코복음", "luke": "03.루카복음", "john": "04.요한복음"}
PREFIX = {"matthew": "마태오복음", "mark": "마르코복음", "luke": "루카복음", "john": "요한복음"}
TOLERANCE_MS = 6000


def parse_tables(src):
    tables = {}
    for book in BOOKS:
        m = re.search(rf"private static let {book}: \[\[Int\]\] = \[(.*?)\n    \]", src, re.S)
        rows = re.findall(r"\[([\d,\s]+)\]", m.group(1))
        tables[book] = [[int(x) for x in row.split(",") if x.strip()] for row in rows]
    return tables


def audio_check(book, chapter, ts, errors):
    import av
    import numpy as np

    path = os.path.join(AUDIO_ROOT, FOLDER[book], f"{PREFIX[book]} {chapter:02d}장.m4a")
    buf = []
    with av.open(path) as container:
        stream = container.streams.audio[0]
        resampler = av.AudioResampler(format="s16", layout="mono", rate=16000)
        for packet in container.demux(stream):
            for frame in packet.decode():
                for rf in resampler.resample(frame):
                    buf.append(rf.to_ndarray().astype(np.float32).reshape(-1) / 32768.0)
    x = np.concatenate(buf)
    duration_ms = len(x) / 16000 * 1000
    if ts[-1] >= duration_ms:
        errors.append(f"{book} {chapter}: last marker {ts[-1]} >= duration {duration_ms:.0f}")
        return

    frame = 800  # 50 ms at 16 kHz
    m = len(x) // frame
    rms = np.sqrt((x[: m * frame].reshape(m, frame) ** 2).mean(axis=1))
    thr = max(np.percentile(rms, 5) * 2.5, rms.max() * 0.02)
    onsets, i = [], 0
    sil = rms < thr
    while i < len(sil):
        if sil[i]:
            j = i
            while j < len(sil) and sil[j]:
                j += 1
            if (j - i) * 50 >= 300:
                onsets.append(j * 50)
            i = j
        else:
            i += 1
    for v, t in enumerate(ts[1:], 2):
        if not any(abs(t - o) <= TOLERANCE_MS for o in onsets):
            errors.append(f"{book} {chapter}:{v} marker {t} has no speech onset within {TOLERANCE_MS} ms")


def main() -> int:
    src = open(SWIFT, encoding="utf-8").read()
    text = json.load(open(TEXT, encoding="utf-8"))
    tables = parse_tables(src)
    do_audio = "--audio" in sys.argv

    errors = []
    chapters = 0
    for book in BOOKS:
        for ci, ts in enumerate(tables[book], 1):
            chapters += 1
            if ts[0] != 0:
                errors.append(f"{book} {ci}: verse 1 is {ts[0]}, expected 0")
            if any(b <= a for a, b in zip(ts, ts[1:])):
                errors.append(f"{book} {ci}: not strictly increasing")
            expected = max(int(v) for v in text[book][str(ci)])
            if len(ts) != expected:
                errors.append(f"{book} {ci}: {len(ts)} markers vs {expected} verses in CBCK text")
            if do_audio:
                try:
                    audio_check(book, ci, ts, errors)
                except ImportError:
                    print("PyAV/numpy not installed — skipping audio checks")
                    do_audio = False

    total = sum(len(ts) for rows in tables.values() for ts in rows)
    if errors:
        print(f"FAIL — {len(errors)} problem(s):")
        for e in errors:
            print("  ", e)
        return 1
    mode = "structural + audio" if "--audio" in sys.argv else "structural"
    print(f"OK — {total} verse markers in {chapters} chapters validated ({mode}).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
