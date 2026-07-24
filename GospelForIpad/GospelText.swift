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

    /// Full title shown with the licensing note.
    var fullName: String {
        switch self {
        case .cck:         return "성경 (한국 천주교 주교회의)"
        case .anniversary: return "200주년 기념 신약성서"
        case .kcb:         return "공동번역 성서"
        case .nab:         return "New American Bible, revised edition (NABRE)"
        }
    }

    /// Copyright / licensing note for this translation. All four texts are
    /// copyrighted (none are public domain); distribution requires permission
    /// from the respective rights holder.
    var licenseNote: String {
        switch self {
        case .cck:
            return "「성경」 © 한국천주교주교회의·한국천주교중앙협의회(CBCK). 저작권 보유 — 배포 시 허가 필요."
        case .anniversary:
            return "「200주년 기념 신약성서」 © 분도출판사. 저작권 보유 — 배포 시 허가 필요."
        case .kcb:
            return "「공동번역 성서」 © 대한성서공회. 저작권 보유 — 배포 시 허가 필요."
        case .nab:
            return "New American Bible, revised edition © Confraternity of Christian Doctrine (USCCB). 배포 시 라이선스 필요."
        }
    }
}

enum GospelText {
    /// translation → gospel → chapter → verse → text
    private static var caches: [BibleTranslation: [String: [String: [String: String]]]] = [:]

    private static func store(for translation: BibleTranslation) -> [String: [String: [String: String]]] {
        if let cached = caches[translation] { return cached }
        var loaded: [String: [String: [String: String]]]
        if
            let url = Bundle.main.url(forResource: translation.resourceName, withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode([String: [String: [String: String]]].self, from: data)
        {
            loaded = decoded
        } else {
            loaded = [:]
        }
        // The 주석성경(공동번역) text carries an inline "[제목;상호참조]" section marker at the
        // start of each pericope. Section headings are now rendered as their own rows from
        // SectionHeadings, so strip the marker here to leave clean verse body text.
        if translation == .kcb {
            loaded = loaded.mapValues { chapters in
                chapters.mapValues { verses in
                    verses.mapValues { stripSectionMarker($0) }
                }
            }
        }
        caches[translation] = loaded
        return loaded
    }

    /// Removes a leading "[제목;상호참조]" section marker (and following whitespace) from
    /// a KCB verse, returning the clean body text.
    private static func stripSectionMarker(_ text: String) -> String {
        guard text.hasPrefix("["), let close = text.firstIndex(of: "]") else { return text }
        let rest = text[text.index(after: close)...]
        return String(rest.drop(while: { $0 == " " || $0 == "\t" }))
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
