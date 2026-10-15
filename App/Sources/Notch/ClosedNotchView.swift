import SwiftUI
import Defaults

/// Kapalı notch: donanım notch'unun iki yanında canlı aktivite içerikleri.
struct ClosedNotchView: View {
    @EnvironmentObject private var model: NotchViewModel
    @ObservedObject private var media = MediaController.shared
    @ObservedObject private var battery = BatteryMonitor.shared
    @ObservedObject private var tray = TrayStore.shared
    @ObservedObject private var calendar = CalendarStore.shared
    @ObservedObject private var pomodoro = PomodoroStore.shared

    var body: some View {
        let activity = model.activeLiveActivity
        let notchHeight = model.closedSize.height - 1
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                leading(activity).frame(width: (activity?.extraWidth ?? 0), alignment: .center)
                Spacer(minLength: model.closedSize.width)
                trailing(activity).frame(width: (activity?.extraWidth ?? 0), alignment: .center)
            }
            .frame(height: notchHeight)
            .padding(.top, 1)
            .padding(.horizontal, model.status == .peeking ? 8 : 0)

            if activity == .media, model.quickPeek == .media {
                Text(media.nowPlaying.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 14)
                    .transition(.opacity)
            }
        }
    }

    @ViewBuilder
    private func leading(_ activity: LiveActivityKind?) -> some View {
        switch activity {
        case .media:
            ArtworkView(image: media.nowPlaying.artwork, cornerRadius: 5)
                .frame(width: 22, height: 22)
        case .charging:
            Image(systemName: battery.isPluggedIn ? "bolt.fill" : "powerplug")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(battery.isPluggedIn ? .green : .white)
        case .tray:
            Image(systemName: "tray.full.fill")
                .font(.system(size: 13))
                .foregroundStyle(.white)
        case .calendar:
            Image(systemName: calendar.upcoming.flatMap(MeetingService.detect) != nil ? "video.fill" : "calendar")
                .font(.system(size: 13))
                .foregroundStyle(calendar.upcoming.map { Color(cgColor: $0.calendar.cgColor) } ?? .white)
        case .pomodoro:
            let phase = pomodoro.justFinished ?? pomodoro.phase
            TimelineView(.periodic(from: .now, by: 1)) { ctx in
                ZStack {
                    Circle().stroke(phase.color.opacity(0.25), lineWidth: 2.5)
                    Circle()
                        .trim(from: 0, to: pomodoro.justFinished != nil ? 1 : max(0.01, pomodoro.progress(at: ctx.date)))
                        .stroke(phase.color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 15, height: 15)
            }
        case nil:
            EmptyView()
        }
    }

    @ViewBuilder
    private func trailing(_ activity: LiveActivityKind?) -> some View {
        switch activity {
        case .media:
            AudioBarsView(isPlaying: media.nowPlaying.isPlaying,
                          color: Defaults[.coloredEffects] ? media.accentColor : .white)
                .frame(width: 18, height: 14)
        case .charging:
            HStack(spacing: 3) {
                Text("\(battery.level)%")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                BatteryGlyph(level: battery.level, charging: battery.isPluggedIn)
            }
        case .tray:
            Text("\(tray.items.count)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        case .calendar:
            TimelineView(.periodic(from: .now, by: 30)) { ctx in
                Text(calendarLabel(at: ctx.date))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
        case .pomodoro:
            if let finished = pomodoro.justFinished {
                Text(finished == .focus ? String(localized: "Break!") : String(localized: "Focus!"))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(finished == .focus ? PomodoroStore.Phase.shortBreak.color : PomodoroStore.Phase.focus.color)
            } else {
                TimelineView(.periodic(from: .now, by: 1)) { ctx in
                    let s = Int(pomodoro.remaining(at: ctx.date).rounded(.up))
                    Text(String(format: "%d:%02d", s / 60, s % 60))
                        .font(.system(size: 11, weight: .semibold, design: .rounded).monospacedDigit())
                        .foregroundStyle(pomodoro.phase.color)
                }
            }
        case nil:
            EmptyView()
        }
    }
}

extension ClosedNotchView {
    func calendarLabel(at date: Date) -> String {
        guard let event = calendar.upcoming else { return "" }
        let minutes = Int(event.startDate.timeIntervalSince(date) / 60)
        return minutes > 0 ? String(localized: "\(minutes) min") : String(localized: "Now")
    }
}

struct BatteryGlyph: View {
    var level: Int
    var charging: Bool
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3).stroke(.white.opacity(0.5), lineWidth: 1)
                .frame(width: 22, height: 11)
            RoundedRectangle(cornerRadius: 1.5)
                .fill(charging ? Color.green : (level <= 20 ? .red : .white))
                .frame(width: max(2, 18 * CGFloat(level) / 100), height: 7)
                .padding(.leading, 2)
        }
        .overlay(alignment: .trailing) {
            RoundedRectangle(cornerRadius: 1).fill(.white.opacity(0.5)).frame(width: 1.5, height: 4).offset(x: 2.5)
        }
    }
}

/// Çalarken hareket eden ses çubukları (albüm renginde).
struct AudioBarsView: View {
    var isPlaying: Bool
    var color: Color
    private let count = 4

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.12, paused: !isPlaying)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            HStack(alignment: .center, spacing: 2) {
                ForEach(0..<count, id: \.self) { i in
                    let phase = sin(t * (5 + Double(i) * 1.7) + Double(i) * 1.3)
                    let h = isPlaying ? 0.35 + 0.65 * abs(phase) : 0.2
                    Capsule().fill(color)
                        .frame(width: 2.5)
                        .scaleEffect(y: h, anchor: .center)
                        .animation(.easeInOut(duration: 0.12), value: h)
                }
            }
        }
    }
}

struct ArtworkView: View {
    var image: NSImage?
    var cornerRadius: CGFloat

    var body: some View {
        Rectangle()
            .fill(LinearGradient(colors: [.gray.opacity(0.5), .gray.opacity(0.25)], startPoint: .top, endPoint: .bottom))
            .overlay {
                if let image {
                    Image(nsImage: image).resizable().aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "music.note").foregroundStyle(.white.opacity(0.7))
                }
            }
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
