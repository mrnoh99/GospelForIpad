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

struct EmbeddedTextView: View {
    @ObservedObject var player: BiblePlayerViewModel
    /// When set (iPhone sheet), a 닫기 button is shown in the header row.
    var onClose: (() -> Void)? = nil
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// Persisted translation selection (shared across launches).
    @AppStorage("embeddedTextTranslation") private var translationRaw = BibleTranslation.cck.rawValue

    @ObservedObject private var fontSettings = FontSettings.shared

    private var translation: BibleTranslation {
        BibleTranslation(rawValue: translationRaw) ?? .cck
    }

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
            translationPicker
                .padding(.top, 14)
            Divider()
                .padding(.vertical, 16)
            verseSection(for: chapter)
            licenseFooter
        }
        .padding(.horizontal, horizontalSizeClass == .regular ? 28 : 16)
        .padding(.top, horizontalSizeClass == .regular ? 28 : 10)
        .padding(.bottom, horizontalSizeClass == .regular ? 28 : 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(uiColor: .systemBackground))
        .accessibilityElement(children: .contain)
    }

    /// Copyright / licensing note for the currently selected translation.
    private var licenseFooter: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: "c.circle")
                .font(.caption2)
            Text(translation.licenseNote)
                .font(.caption2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(.tertiary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
        .accessibilityLabel("본문 저작권: \(translation.licenseNote)")
    }

    // MARK: - Header

    /// iPhone(compact)에서는 헤더 글자를 줄인다.
    private var titleFontSize: CGFloat { horizontalSizeClass == .regular ? 34 : 22 }
    private var subtitleFontSize: CGFloat { horizontalSizeClass == .regular ? 20 : 15 }

    private func header(for chapter: BibleChapter) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                chapterNavButton("chevron.left", label: "이전 장") {
                    player.stepDisplayedChapter(-1)
                }

                Text(chapter.title)
                    .font(.app(titleFontSize, relativeTo: horizontalSizeClass == .regular ? .largeTitle : .title3))
                    .fontWeight(.bold)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                chapterNavButton("chevron.right", label: "다음 장") {
                    player.stepDisplayedChapter(1)
                }

                if isLive {
                    Label("재생 중", systemImage: "speaker.wave.2.fill")
                        .font(.caption.bold())
                        .labelStyle(.titleAndIcon)
                        .foregroundStyle(Color.accentColor)
                }

                Spacer(minLength: 8)

                fontMenu

                if let onClose {
                    Button("닫기", action: onClose)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.accentColor.opacity(0.14)))
                        .buttonStyle(.plain)
                        .accessibilityLabel("본문 닫기")
                }
            }

            let subtitle = chapter.subtitle
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.app(subtitleFontSize, relativeTo: .title3))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }

    private func chapterNavButton(_ systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 34, height: 34)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: - Font toggle

    private var fontMenu: some View {
        Button {
            fontSettings.toggle()
        } label: {
            Text(fontSettings.choice.shortLabel)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.accentColor.opacity(0.14)))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("글꼴: \(fontSettings.choice.label)")
        .accessibilityHint("탭하면 글꼴을 바꿉니다")
    }

    // MARK: - Translation tab

    private var translationPicker: some View {
        Picker("성경 번역", selection: $translationRaw) {
            ForEach(BibleTranslation.allCases) { translation in
                Text(translation.shortName).tag(translation.rawValue)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: .infinity)
        .accessibilityLabel("성경 번역 선택")
    }

    // MARK: - Verse text

    @ViewBuilder
    private func verseSection(for chapter: BibleChapter) -> some View {
        let verses = chapter.verses(in: translation)
        if verses.isEmpty {
            unavailableText
        } else {
            let headings = Dictionary(
                SectionHeadings.headings(gospel: chapter.gospel, chapter: chapter.number)
                    .map { ($0.verse, $0.title) },
                uniquingKeysWith: { first, _ in first }
            )
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(verses, id: \.verse) { item in
                            if let title = headings[item.verse] {
                                SectionHeadingRow(title: title)
                            }
                            VerseRow(
                                verse: item.verse,
                                text: item.text,
                                isCurrent: item.verse == currentVerse,
                                onTap: { player.playVerse(chapter, verse: item.verse) }
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

// MARK: - Section heading row

/// A pericope section heading (소제목) rendered as its own row above the verse it starts.
private struct SectionHeadingRow: View {
    let title: String
    @ObservedObject private var fontSettings = FontSettings.shared

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.accentColor)
                .frame(width: 3, height: 18)
            Text(title)
                .font(.app(18, relativeTo: .headline, bold: true))
                .foregroundStyle(Color.accentColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.top, 18)
        .padding(.bottom, 4)
        .accessibilityAddTraits(.isHeader)
        .accessibilityLabel("소제목: \(title)")
    }
}

// MARK: - Verse row

private struct VerseRow: View {
    let verse: Int
    let text: String
    let isCurrent: Bool
    var onTap: () -> Void = {}
    @ObservedObject private var fontSettings = FontSettings.shared

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(verse)")
                .font(.app(16, relativeTo: .callout))
                .fontWeight(.bold)
                .foregroundStyle(isCurrent ? Color.accentColor : .secondary)
                .frame(minWidth: 30, alignment: .trailing)

            Text(text.isEmpty ? "—" : text)
                .font(.app(20, relativeTo: .title3))
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
        .onTapGesture(perform: onTap)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(verse)절")
        .accessibilityValue(isCurrent ? "재생 중. \(text)" : text)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("이 절부터 재생합니다")
    }
}
