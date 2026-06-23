//
//  PlaybackGlassMenu.swift
//  GospelForIpad
//

import SwiftUI

/// Apple Music–style Liquid Glass playback bar: previous / play-stop / next,
/// a repeat toggle (off · 전체반복 · 장반복) and a knobless progress bar.
/// Keeps the original bar height.
struct PlaybackGlassMenu: View {
    let barHeight: CGFloat
    let chapterTitle: String
    let isPlaying: Bool
    let elapsed: TimeInterval
    let duration: TimeInterval
    let repeatMode: RepeatMode
    let onPlayStop: () -> Void
    let onBackward: () -> Void
    let onForward: () -> Void
    let onCycleRepeat: () -> Void

    @ScaledMetric(relativeTo: .body) private var menuHorizontalPadding: CGFloat = AppControlLayout.barHorizontalPadding

    init(
        barHeight: CGFloat = AppControlLayout.barHeight,
        chapterTitle: String,
        isPlaying: Bool,
        elapsed: TimeInterval = 0,
        duration: TimeInterval = 0,
        repeatMode: RepeatMode = .off,
        onPlayStop: @escaping () -> Void,
        onBackward: @escaping () -> Void = {},
        onForward: @escaping () -> Void = {},
        onCycleRepeat: @escaping () -> Void = {}
    ) {
        self.barHeight = barHeight
        self.chapterTitle = chapterTitle
        self.isPlaying = isPlaying
        self.elapsed = elapsed
        self.duration = duration
        self.repeatMode = repeatMode
        self.onPlayStop = onPlayStop
        self.onBackward = onBackward
        self.onForward = onForward
        self.onCycleRepeat = onCycleRepeat
    }

    private var progress: Double {
        guard duration > 0, elapsed.isFinite else { return 0 }
        return min(max(elapsed / duration, 0), 1)
    }

    private var repeatIcon: String { repeatMode == .one ? "repeat.1" : "repeat" }
    private var repeatActive: Bool { repeatMode != .off }

    var body: some View {
        controlsRow
            .frame(height: barHeight)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .bottom) { progressBar }
            .modifier(GlassCapsuleSurfaceModifier(
                horizontalPadding: menuHorizontalPadding,
                cornerRadius: AppControlLayout.barCornerRadius
            ))
    }

    private var controlsRow: some View {
        HStack(spacing: 14) {
            iconButton(
                systemName: repeatIcon,
                label: repeatAccessibilityLabel,
                tint: repeatActive ? Color.accentColor : Color.secondary,
                action: onCycleRepeat
            )

            Text(chapterTitle)
                .font(AppControlTypography.prominentLabelFont)
                .foregroundStyle(Color.accentColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityHidden(true)

            iconButton(systemName: "backward.fill", label: "이전 장", action: onBackward)

            Button(action: onPlayStop) {
                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    .font(.title3)
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.accentColor)
            .accessibilityLabel(AccessibilitySupport.playbackButtonLabel(chapterTitle: chapterTitle, isPlaying: isPlaying))
            .accessibilityHint(isPlaying ? "재생을 멈춥니다" : "선택한 장을 재생합니다")
            .accessibilityIdentifier("playback-button")

            iconButton(systemName: "forward.fill", label: "다음 장", action: onForward)
        }
    }

    private func iconButton(
        systemName: String,
        label: String,
        tint: Color = Color.accentColor,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.body)
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(tint)
        .accessibilityLabel(label)
    }

    private var repeatAccessibilityLabel: String {
        switch repeatMode {
        case .off: return "반복 끄기"
        case .all: return "전체 반복"
        case .one: return "한 장 반복"
        }
    }

    /// Thin, knobless progress bar pinned to the bottom edge (does not change bar height).
    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.25))
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: geo.size.width * progress)
            }
        }
        .frame(height: 3)
        .padding(.horizontal, 10)
        .padding(.bottom, 4)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
