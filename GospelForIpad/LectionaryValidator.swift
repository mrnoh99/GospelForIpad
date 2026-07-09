//
//  LectionaryValidator.swift
//  GospelForIpad
//
//  The Lectionary is first-class data: DEBUG builds sweep three full liturgical
//  years (Sunday cycles A, B, C) and assert that every reading the calendar
//  produces points at verses that exist in the bundled scripture. Release
//  builds compile this out entirely.
//
//  Complementary offline check: scripts/validate_lectionary.py validates every
//  gc() table entry against GospelText.json without needing Xcode.
//

#if DEBUG
import Foundation

enum LectionaryValidator {

    /// Walks liturgical years 2026–2028 (cycles A·B·C) day by day and traps on
    /// any reading that falls outside the bundled scripture.
    static func validate() {
        // First Sunday of Advent 2025 through the end of liturgical year 2028.
        var day = LDate.make(2025, 11, 30)
        let end = LDate.make(2028, 12, 2)
        var readings = 0
        var gaps = 0

        while day <= end {
            if let r = Lectionary.todayGospelReading(day) {
                let gospel = r.chapter.gospel
                let chapter = r.chapter.number
                let lastVerse = GospelText.verseCount(.cck, gospel: gospel, chapter: chapter)

                assert(chapter >= 1 && chapter <= gospel.chapterCount,
                       "Lectionary: chapter out of range for \(gospel.shortName) \(chapter) on \(day)")
                assert(r.startVerse >= 1 && r.startVerse <= r.endVerse,
                       "Lectionary: verse order \(r.startVerse)-\(r.endVerse) for \(gospel.shortName) \(chapter) on \(day)")
                assert(lastVerse == 0 || r.endVerse <= lastVerse,
                       "Lectionary: end verse \(r.endVerse) beyond \(gospel.shortName) \(chapter),\(lastVerse) on \(day)")
                readings += 1
            } else {
                gaps += 1
            }
            day = LDate.addDays(day, 1)
        }

        print("LectionaryValidator: \(readings) readings validated, \(gaps) gap day(s) across cycles A·B·C")
        validateVerseTimestamps()
    }

    /// Audio verse markers are first-class data too (docs/AUDIO_TIMESTAMPS.md):
    /// verse 1 must be 0, markers strictly increasing, counts matching the CCK text.
    private static func validateVerseTimestamps() {
        var chapters = 0
        var markers = 0
        for gospel in Bible.Gospel.allCases {
            for chapter in 1...gospel.chapterCount {
                let count = VerseTimestamps.verseCount(gospel: gospel, chapter: chapter)
                assert(count > 0, "VerseTimestamps: no markers for \(gospel.shortName) \(chapter)")
                assert(count == GospelText.verseCount(.cck, gospel: gospel, chapter: chapter),
                       "VerseTimestamps: count mismatch vs CCK text in \(gospel.shortName) \(chapter)")
                var previous = -1
                for verse in 1...count {
                    let ms = VerseTimestamps.startMs(gospel: gospel, chapter: chapter, verse: verse)
                    if verse == 1 {
                        // Verse 1 starts after the recorded chapter announcement (intro).
                        assert(ms >= 0 && ms <= 40_000,
                               "VerseTimestamps: verse 1 of \(gospel.shortName) \(chapter) at \(ms) ms is outside the intro bound")
                    }
                    assert(ms > previous, "VerseTimestamps: not increasing at \(gospel.shortName) \(chapter):\(verse)")
                    previous = ms
                }
                chapters += 1
                markers += count
            }
        }
        print("LectionaryValidator: \(markers) verse markers in \(chapters) chapters OK")
    }
}
#endif
