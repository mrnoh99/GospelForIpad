//
//  BibleChapter+Text.swift
//  GospelForIpad
//
//  Bridges each chapter to the bible text data ported from
//  ListenToGospel-Android (ChapterTitles / VerseTimestamps).
//

import Foundation

extension BibleChapter {
    /// Section heading for the chapter (e.g. "예수 그리스도의 족보; 예수 그리스도의 탄생").
    var subtitle: String {
        ChapterTitles.subtitle(for: gospel, chapter: number)
    }

    /// Number of verses with known start timestamps (0 when unknown).
    var knownVerseCount: Int {
        VerseTimestamps.verseCount(gospel: gospel, chapter: number)
    }

    /// Estimated start time of a 1-based verse, in seconds.
    func verseStartSeconds(_ verse: Int) -> TimeInterval {
        TimeInterval(VerseTimestamps.startMs(gospel: gospel, chapter: number, verse: verse)) / 1000
    }

    /// The 1-based verse playing at the given elapsed time, or nil when unknown.
    func currentVerse(elapsedSeconds: TimeInterval) -> Int? {
        VerseTimestamps.currentVerse(
            gospel: gospel,
            chapter: number,
            elapsedMs: Int((elapsedSeconds * 1000).rounded(.down))
        )
    }

    /// Ordered scripture verses (number + body text) for this chapter.
    var verses: [(verse: Int, text: String)] {
        GospelText.verses(gospel: gospel, chapter: number)
    }
}
