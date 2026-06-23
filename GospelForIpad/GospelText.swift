//
//  GospelText.swift
//  GospelForIpad
//
//  Loads the Korean Gospel verse text bundled as JSON and exposes it per
//  translation / gospel / chapter / verse. This is the body text shown in the
//  synchronized embedded-text reading panel.
//

import Foundation

/// Available Korean Gospel translations the reader can switch between.
enum BibleTranslation: String, CaseIterable, Identifiable, Sendable {
    case cck          // 한국 천주교 주교회의 「성경」
    case anniversary  // 200주년 기념 성서
    case kcb          // 공동번역 성서 (Korean Common Bible)
    // NAB / NABRE (New American Bible, revised edition).
    // ⚠️ Copyright © Confraternity of Christian Doctrine (USCCB). Bundling the
    // full Gospel text in a distributed app (free or paid) requires a USCCB/CCD
    // license + permissions fee. Ship only after that license is secured.
    case nab

    var id: String { rawValue }

    /// Short label for the tab/segmented control.
    var shortName: String {
        switch self {
        case .cck:         return "성경"
        case .anniversary: return "200주년"
        case .kcb:         return "공동번역"
        case .nab:         return "NAB"
        }
    }

    /// Bundled JSON resource name (without extension).
    var resourceName: String {
        switch self {
        case .cck:         return "GospelText"
        case .anniversary: return "GospelText200"
        case .kcb:         return "GospelTextKCB"
        case .nab:         return "GospelTextNAB"
        }
    }
}

enum GospelText {
    /// translation → gospel → chapter → verse → text
    private static var caches: [BibleTranslation: [String: [String: [String: String]]]] = [:]

    private static func store(for translation: BibleTranslation) -> [String: [String: [String: String]]] {
        if let cached = caches[translation] { return cached }
        let loaded: [String: [String: [String: String]]]
        if
            let url = Bundle.main.url(forResource: translation.resourceName, withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode([String: [String: [String: String]]].self, from: data)
        {
            loaded = decoded
        } else {
            loaded = [:]
        }
        caches[translation] = loaded
        return loaded
    }

    private static func key(for gospel: Bible.Gospel) -> String {
        switch gospel {
        case .matthew: return "matthew"
        case .mark:    return "mark"
        case .luke:    return "luke"
        case .john:    return "john"
        }
    }

    /// Verse text for a 1-based verse, or nil when unavailable.
    static func verse(_ translation: BibleTranslation, gospel: Bible.Gospel, chapter: Int, verse: Int) -> String? {
        store(for: translation)[key(for: gospel)]?[String(chapter)]?[String(verse)]
    }

    /// Highest verse number available for a chapter (0 when none).
    static func verseCount(_ translation: BibleTranslation, gospel: Bible.Gospel, chapter: Int) -> Int {
        guard let chapterDict = store(for: translation)[key(for: gospel)]?[String(chapter)] else { return 0 }
        return chapterDict.keys.compactMap { Int($0) }.max() ?? 0
    }

    /// Ordered (verse, text) pairs for a chapter, ascending by verse number.
    static func verses(_ translation: BibleTranslation, gospel: Bible.Gospel, chapter: Int) -> [(verse: Int, text: String)] {
        guard let chapterDict = store(for: translation)[key(for: gospel)]?[String(chapter)] else { return [] }
        return chapterDict
            .compactMap { rawKey, text in Int(rawKey).map { (verse: $0, text: text) } }
            .sorted { $0.verse < $1.verse }
    }
}
