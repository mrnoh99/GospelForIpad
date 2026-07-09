#!/usr/bin/env python3
"""Validate the Lectionary data in GospelForIpad/Lectionary.swift.

The Lectionary is first-class data: every reading reference must point at a
verse that actually exists in the bundled scripture. This script parses every
gc(<book>, <chapter>, <start>, <end>) call and checks it against the bundled
CCK text (GospelText.json), which is the app's ground truth for Catholic
versification.

Checks
  1. chapter is within the book's chapter count
  2. 1 <= start <= end
  3. end <= last verse of that chapter in GospelText.json
  4. weekday tables have exactly 6 columns (Mon..Sat) per row

Exit code 0 = all good; 1 = violations found (printed).
Run:  python3 scripts/validate_lectionary.py
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SWIFT = os.path.join(ROOT, "GospelForIpad", "Lectionary.swift")
TEXT = os.path.join(ROOT, "GospelForIpad", "GospelText.json")

BOOK_KEY = {"M": "matthew", "Mk": "mark", "L": "luke", "J": "john"}
CHAPTER_COUNT = {"M": 28, "Mk": 16, "L": 24, "J": 21}

def main() -> int:
    text = json.load(open(TEXT, encoding="utf-8"))
    max_verse = {
        (abbr, ch): max(int(v) for v in verses)
        for abbr, key in BOOK_KEY.items()
        for ch, verses in ((int(c), vs) for c, vs in text[key].items())
    }

    src = open(SWIFT, encoding="utf-8").read()
    errors = []

    for lineno, line in enumerate(src.splitlines(), 1):
        for m in re.finditer(r"gc\((M|Mk|L|J),\s*(\d+),\s*(\d+),\s*(\d+)\)", line):
            book, ch, start, end = m.group(1), int(m.group(2)), int(m.group(3)), int(m.group(4))
            ref = f"{book} {ch},{start}-{end} (line {lineno})"
            if not (1 <= ch <= CHAPTER_COUNT[book]):
                errors.append(f"chapter out of range: {ref}")
                continue
            if not (1 <= start <= end):
                errors.append(f"start/end order: {ref}")
            last = max_verse[(book, ch)]
            if end > last:
                errors.append(f"end beyond last verse ({last}): {ref}")

        # weekday table rows must be Mon..Sat = 6 entries
        stripped = line.strip()
        if stripped.startswith("[gc(") and stripped.rstrip(",").endswith(")]"):
            count = len(re.findall(r"gc\(", stripped))
            if count != 6:
                errors.append(f"weekday row has {count} entries (want 6): line {lineno}")

    calls = len(re.findall(r"gc\((M|Mk|L|J),", src))
    bare = len(re.findall(r"gc\((M|Mk|L|J),\s*\d+,\s*\d+\)", src))
    if bare:
        errors.append(f"{bare} gc() calls missing an end verse")

    if errors:
        print(f"FAIL — {len(errors)} problem(s) in {calls} references:")
        for e in errors:
            print("  ", e)
        return 1
    print(f"OK — {calls} lectionary references validated against bundled scripture.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
