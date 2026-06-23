//
//  TodayGospelView.swift
//  GospelForIpad
//
//  "오늘의 말씀" card: shows the Mass Gospel reading for a date (with prev/next/
//  today navigation) and plays it from the reading's start verse. Ported from
//  the ListenToGospel-Android TodayGospelButton.
//

import SwiftUI

struct TodayGospelView: View {
    @ObservedObject var player: BiblePlayerViewModel
    /// When set (compact layout), tapping the reading info opens it for reading.
    var onOpenReading: ((Lectionary.Reading) -> Void)? = nil
    @ObservedObject private var fontSettings = FontSettings.shared
    @State private var viewedDate: Date = LDate.today()

    private var reading: Lectionary.Reading? {
        Lectionary.todayGospelReading(viewedDate)
    }

    private var liturgicalName: String {
        LiturgicalCalendar.liturgicalDayName(viewedDate)
    }

    private var isToday: Bool { viewedDate == LDate.today() }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.timeZone = LDate.calendar.timeZone
        f.dateFormat = "yyyy년 M월 d일 (E)"
        return f
    }()

    private var dateLabel: String {
        Self.dateFormatter.string(from: viewedDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            topRow
            readingRow
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .accessibilityElement(children: .contain)
    }

    // MARK: - Top row (date + navigation)

    private var topRow: some View {
        HStack(spacing: 12) {
            Text(dateLabel)
                .font(.app(15, relativeTo: .subheadline))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)

            navButton("chevron.left", label: "이전 날") {
                viewedDate = LDate.addDays(viewedDate, -1)
            }

            Button {
                viewedDate = LDate.today()
            } label: {
                Text("오늘")
                    .font(.app(15, relativeTo: .subheadline))
                    .fontWeight(.semibold)
                    .foregroundStyle(isToday ? Color.secondary.opacity(0.5) : Color.accentColor)
            }
            .buttonStyle(.plain)
            .disabled(isToday)
            .accessibilityLabel("오늘의 복음으로 돌아가기")

            navButton("chevron.right", label: "다음 날") {
                viewedDate = LDate.addDays(viewedDate, 1)
            }
        }
    }

    private func navButton(_ systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: - Reading row (liturgical name + chapter/verse + play)

    @ViewBuilder
    private var readingRow: some View {
        if let reading {
            HStack(alignment: .center, spacing: 12) {
                HStack(spacing: 6) {
                    Text(liturgicalName)
                        .font(.app(15, relativeTo: .subheadline))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    Text(chapterLabel(for: reading))
                        .font(.app(16, relativeTo: .callout))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.accentColor)
                        .lineLimit(1)
                        .fixedSize()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    preview(reading)
                    onOpenReading?(reading)
                }

                Button {
                    player.playChapter(reading.chapter, startVerse: reading.startVerse)
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("오늘의 복음 재생: \(chapterLabel(for: reading))")
            }
        } else {
            VStack(alignment: .leading, spacing: 3) {
                Text(liturgicalName)
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                Text("이 앱의 네 복음서에 없는 본문입니다.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func chapterLabel(for reading: Lectionary.Reading) -> String {
        let c = reading.chapter
        return "\(c.gospel.shortName) \(c.number)장 \(reading.startVerse)절"
    }

    /// Selects the reading's chapter so the embedded-text panel previews it (without playing).
    private func preview(_ reading: Lectionary.Reading) {
        if player.selectedGospel != reading.chapter.gospel {
            player.selectedGospel = reading.chapter.gospel
        }
        player.selectChapter(reading.chapter)
    }
}
