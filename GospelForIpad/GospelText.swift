//
//  GospelText.swift
//  GospelForIpad
//
//  Loads the Korean Gospel verse text (CCK) bundled as GospelText.json and
//  exposes it per gospel / chapter / verse. This is the body text shown in the
//  synchronized embedded-text reading panel.
//

import Foundation

enum GospelText {
    /// gospel → chapter → verse → text
    private static let store: [String: [String: [String: String]]] = {
        guard
            let url = Bundle.main.url(forResource: "GospelText", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode([String: [String: [String: String]]].self, from: data)
        else {
            return [:]
        }
        return decoded
    }()

    private static func key(for gospel: Bible.Gospel) -> String {
        switch gospel {
        case .matthew: return "matthew"
        case .mark:    return "mark"
        case .luke:    return "luke"
        case .john:    return "john"
        }
    }

    /// Verse text for a 1-based verse, or nil when unavailable.
    static func verse(gospel: Bible.Gospel, chapter: Int, verse: Int) -> String? {
        store[key(for: gospel)]?[String(chapter)]?[String(verse)]
    }

    /// Highest verse number available for a chapter (0 when none).
    static func verseCount(gospel: Bible.Gospel, chapter: Int) -> Int {
        guard let chapterDict = store[key(for: gospel)]?[String(chapter)] else { return 0 }
        return chapterDict.keys.compactMap { Int($0) }.max() ?? 0
    }

    /// Ordered (verse, text) pairs for a chapter, ascending by verse number.
    static func verses(gospel: Bible.Gospel, chapter: Int) -> [(verse: Int, text: String)] {
        guard let chapterDict = store[key(for: gospel)]?[String(chapter)] else { return [] }
        return chapterDict
            .compactMap { rawKey, text in Int(rawKey).map { (verse: $0, text: text) } }
            .sorted { $0.verse < $1.verse }
    }
}
