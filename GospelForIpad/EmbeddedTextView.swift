//
//  EmbeddedTextView.swift
//  GospelForIpad
//
//  iPad reading panel that shows the "embedded text" for the active chapter:
//  the section heading plus a verse ruler that highlights and follows the
//  currently playing verse, driven by the bible data imported from
//  ListenToGospel-Android (ChapterTitles / VerseTimestamps).
//

import SwiftUI

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
                    .font(.largeTitle.bold())
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
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Verse ruler

    @ViewBuilder
    private func verseSection(for chapter: BibleChapter) -> some View {
        let verseCount = chapter.knownVerseCount
        if verseCount <= 0 {
            unavailableText
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(1...verseCount, id: \.self) { verse in
                            VerseRow(
                                verse: verse,
                                startSeconds: chapter.verseStartSeconds(verse),
                                isCurrent: verse == currentVerse
                            )
                            .id(verse)
                        }
                    }
                    .padding(.bottom, 24)
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
            Text("이 장의 절 정보가 아직 없습니다.")
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
    let startSeconds: TimeInterval
    let isCurrent: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text("\(verse)절")
                .font(.title3.weight(isCurrent ? .bold : .regular))
                .foregroundStyle(isCurrent ? Color.accentColor : .primary)
                .frame(minWidth: 56, alignment: .leading)

            Text(timestampText)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(isCurrent ? Color.accentColor.opacity(0.9) : .secondary)

            Spacer(minLength: 0)

            if isCurrent {
                Image(systemName: "headphones")
                    .font(.subheadline)
                    .foregroundStyle(Color.accentColor)
            }
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
        .accessibilityValue(isCurrent ? "재생 중" : "")
    }

    private var timestampText: String {
        let total = Int(startSeconds.rounded(.down))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
