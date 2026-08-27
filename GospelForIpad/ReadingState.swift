//
//  ReadingState.swift
//  GospelForIpad
//
//  Manages reading position and history for Bible chapters
//

import Foundation

@Observable
final class ReadingState {
    var lastBookIDs: [String: String] = [:]
    var lastChapters: [String: [String: Int]] = [:]

    static let shared = ReadingState()

    private let userDefaults = UserDefaults.standard
    private let lastBookKey = "lastBookID"
    private let lastChapterKey = "lastChapter"

    init() {
        loadDefaults()
    }

    func lastChapter(edition: Edition?, book: BibleBook) -> Int {
        guard let edition = edition else { return 1 }
        if let chapters = lastChapters[edition.id], let chapter = chapters[book.id] {
            return max(1, min(chapter, book.chapterCount))
        }
        return 1
    }

    func savePosition(edition: Edition?, book: BibleBook, chapter: Int) {
        guard let edition = edition else { return }

        lastBookIDs[edition.id] = book.id

        if lastChapters[edition.id] == nil {
            lastChapters[edition.id] = [:]
        }
        lastChapters[edition.id]?[book.id] = chapter

        saveDefaults()
    }

    private func loadDefaults() {
        if let data = userDefaults.data(forKey: "lastBookIDs"),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            lastBookIDs = decoded
        }

        if let data = userDefaults.data(forKey: "lastChapters"),
           let decoded = try? JSONDecoder().decode([String: [String: Int]].self, from: data) {
            lastChapters = decoded
        }
    }

    private func saveDefaults() {
        if let data = try? JSONEncoder().encode(lastBookIDs) {
            userDefaults.set(data, forKey: "lastBookIDs")
        }
        if let data = try? JSONEncoder().encode(lastChapters) {
            userDefaults.set(data, forKey: "lastChapters")
        }
    }
}
