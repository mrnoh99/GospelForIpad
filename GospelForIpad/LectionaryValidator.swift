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
    }
}
#endif
