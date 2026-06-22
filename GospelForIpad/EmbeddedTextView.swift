//
//  EmbeddedTextView.swift
//  GospelForIpad
//
//  iPad reading panel that shows the "embedded text" for the active chapter:
//  the section heading plus the Gospel verse body text (CCK), highlighting and
//  auto-scrolling to the verse currently being read. The current verse is
//  derived from the playback position and the imported verse timestamps
//  (VerseTimestamps); the body text comes from GospelText.
//

import SwiftUI

/// Myeongjo (serif) font used throughout the reading panel.
private extension Font {
    static func myeongjo(_ size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        .custom("AppleMyungjo", size: size, relativeTo: style)
    }
}


struct EmbeddedTextView: View {
    @ObservedObject var player: BiblePlayerViewModel

    /// Chapter whose text we display: the one playing, otherwise the selection.
    private var displayChapter: BibleChapter {
        player.currentPlayingChapter ?? player.selectedChapter
    }

    /// True when the displayed chapter is the one actively playing.
    private var isLive: Bool {
        player.isPlaying && player.currentPlayingChapter == displayChapter
    }

    /// 1-based verse currently being read (only while live).
    private var currentVerse: Int? {
        guard isLive else { return nil }
        return displayChapter.currentVerse(elapsedSeconds: player.playbackElapsedSeconds)
    }

    var body: some View {
        let chapter = displayChapter
        VStack(alignment: .leading, spacing: 0) {
            header(for: chapter)
            Divider()
                .padding(.vertical, 16)
            verseSection(for: chapter)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(uiColor: .systemBackground))
        .accessibilityElement(children: .contain)
    }

    // MARK: - Header

    @ViewBuilder
    private func header(for chapter: BibleChapter) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(chapter.title)
                    .font(.myeongjo(34, relativeTo: .largeTitle))
                    .fontWeight(.bold)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                if isLive {
                    Label("재생 중", systemImage: "speaker.wave.2.fill")
                        .font(.caption.bold())
                        .labelStyle(.titleAndIcon)
                        .foregroundStyle(Color.accentColor)
                }
            }

            let subtitle = chapter.subtitle
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.myeongjo(20, relativeTo: .title3))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Verse text

    @ViewBuilder
    private func verseSection(for chapter: BibleChapter) -> some View {
        let verses = chapter.verses
        if verses.isEmpty {
            unavailableText
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(verses, id: \.verse) { item in
                            VerseRow(
                                verse: item.verse,
                                text: item.text,
                                isCurrent: item.verse == currentVerse
                            )
                            .id(item.verse)
                        }
                    }
                    .padding(.bottom, 32)
                }
                .onChange(of: currentVerse) { _, newValue in
                    guard let verse = newValue else { return }
                    withAnimation(.easeInOut(duration: 0.25)) {
                        proxy.scrollTo(verse, anchor: .center)
                    }
                }
            }
        }
    }

    private var unavailableText: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("이 장의 본문이 아직 없습니다.")
                .font(.body)
                .foregroundStyle(.secondary)
            Text("오디오를 재생하면 본문 위치가 함께 표시됩니다.")
                .font(.callout)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Verse row

private struct VerseRow: View {
    let verse: Int
    let text: String
    let isCurrent: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(verse)")
                .font(.myeongjo(16, relativeTo: .callout))
                .fontWeight(.bold)
                .foregroundStyle(isCurrent ? Color.accentColor : .secondary)
                .frame(minWidth: 30, alignment: .trailing)

            Text(text.isEmpty ? "—" : text)
                .font(.myeongjo(20, relativeTo: .title3))
                .lineSpacing(4)
                .foregroundStyle(Color.primary.opacity(isCurrent ? 1 : 0.85))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isCurrent ? Color.accentColor.opacity(0.16) : Color.clear)
        )
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(verse)절")
        .accessibilityValue(isCurrent ? "재생 중. \(text)" : text)
    }
}
