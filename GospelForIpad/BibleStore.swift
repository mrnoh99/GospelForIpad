//
//  BibleStore.swift
//  GospelForIpad
//
//  Minimal Bible data types for GospelForIpad
//  Note: GospelForIpad uses GospelText.swift for actual text rendering
//

import Foundation
import Observation

// Core types for Bible data representation
nonisolated struct Verse: Identifiable, Hashable, Sendable {
    let number: Int
    let text: String

    var id: Int { number }
}

nonisolated struct SectionTitle: Identifiable, Hashable, Sendable {
    let verse: String
    let text: String

    var id: String { verse }
}

// Minimal BibleStore - GospelForIpad uses GospelText.swift instead
@Observable
final class BibleStore {
    static let shared = BibleStore()

    private(set) var isLoaded = false

    func load() async {
        // No-op: GospelForIpad doesn't use BibleStore
        isLoaded = true
    }

    func verses(edition: Edition?, book: BibleBook, chapter: Int) -> [Verse] {
        [] // GospelText.swift handles actual verse retrieval
    }

    func bookName(edition: Edition?, book: BibleBook) -> String {
        book.name
    }

    func bookShortName(edition: Edition?, book: BibleBook) -> String {
        book.shortName
    }

    func titles(edition: Edition?, book: BibleBook, chapter: Int) -> [SectionTitle] {
        []
    }
}
