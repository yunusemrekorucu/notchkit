import SwiftUI

struct MediaWidget: View {
    @ObservedObject private var media = MediaController.shared
    @State private var scrubbing: Double?

    var body: some View {
        let np = media.nowPlaying
        GeometryReader { proxy in
            HStack(spacing: 12) {
                ArtworkView(image: np.artwork, cornerRadius: 12)
                    .frame(width: proxy.size.height, height: proxy.size.height)
                    .layoutPriority(1)
                    .overlay(alignment: .bottomTrailing) {
                        if let icon = np.appIcon {
                            Image(nsImage: icon).resizable().frame(width: 22, height: 22)
                                .offset(x: 5, y: 5)
                                .shadow(radius: 3)
                        }
                    }
                    .onTapGesture { media.openSourceApp() }
                    .shadow(color: media.accentColor.opacity(np.isEmpty ? 0 : 0.35), radius: 12)

                VStack(alignment: .leading, spacing: 4) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(np.isEmpty ? String(localized: "Nothing is playing") : np.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                        Text(np.isEmpty ? String(localized: "Start music in any app") : np.artist)
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .lineLimit(1)

                    TimelineView(.periodic(from: .now, by: 0.5)) { ctx in
                        let elapsed = scrubbing ?? np.elapsed(at: ctx.date)
                        ProgressScrubber(value: elapsed, total: max(np.duration, 1), color: media.accentColor,
                                         scrubbing: $scrubbing) { media.seek(to: $0) }
                            .disabled(np.isEmpty || np.duration <= 0)
                    }

                    HStack(spacing: 6) {
                        Spacer(minLength: 0)
                        NookButton(symbol: "backward.fill", fontSize: 14) { media.send(.previousTrack) }
                        NookButton(symbol: np.isPlaying ? "pause.fill" : "play.fill", size: 34, fontSize: 20) {
                            media.send(.togglePlayPause)
                        }
                        NookButton(symbol: "forward.fill", fontSize: 14) { media.send(.nextTrack) }
                        Spacer(minLength: 0)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct ProgressScrubber: View {
    var value: Double
    var total: Double
    var color: Color
    @Binding var scrubbing: Double?
    var onCommit: (Double) -> Void
    @State private var hovering = false

    var body: some View {
        VStack(spacing: 2) {
            GeometryReader { proxy in
                let fraction = min(max(value / total, 0), 1)
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.18))
                    Capsule().fill(color).frame(width: proxy.size.width * fraction)
                }
                .frame(height: hovering || scrubbing != nil ? 7 : 5)
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { g in scrubbing = min(max(g.location.x / proxy.size.width, 0), 1) * total }
                    .onEnded { _ in
                        if let s = scrubbing { onCommit(s) }
                        scrubbing = nil
                    })
            }
            .frame(height: 10)
            .onHover { h in withAnimation(.easeOut(duration: 0.12)) { hovering = h } }

            HStack {
                Text(format(value))
                Spacer()
                Text("-" + format(max(total - value, 0)))
            }
            .font(.system(size: 10, weight: .medium, design: .rounded).monospacedDigit())
            .foregroundStyle(.white.opacity(0.5))
        }
    }

    private func format(_ t: Double) -> String {
        let s = Int(t.rounded(.down))
        return s >= 3600 ? String(format: "%d:%02d:%02d", s / 3600, s / 60 % 60, s % 60)
                         : String(format: "%d:%02d", s / 60, s % 60)
    }
}
