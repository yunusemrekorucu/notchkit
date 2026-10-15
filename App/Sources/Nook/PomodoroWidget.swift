import SwiftUI
import AppKit
import Defaults

/// Odak → kısa mola → … → uzun mola döngüsünü yöneten Pomodoro sayacı.
@MainActor
final class PomodoroStore: ObservableObject {
    static let shared = PomodoroStore()

    enum Phase: Equatable {
        case focus, shortBreak, longBreak

        var title: String {
            switch self {
            case .focus: "Odak"
            case .shortBreak: "Kısa mola"
            case .longBreak: "Uzun mola"
            }
        }

        var symbol: String {
            switch self {
            case .focus: "target"
            case .shortBreak: "cup.and.saucer.fill"
            case .longBreak: "figure.walk"
            }
        }

        var color: Color {
            switch self {
            case .focus: Color(red: 1, green: 0.38, blue: 0.3)
            case .shortBreak: Color(red: 0.3, green: 0.85, blue: 0.5)
            case .longBreak: Color(red: 0.35, green: 0.65, blue: 1)
            }
        }

        var duration: TimeInterval {
            let minutes = switch self {
            case .focus: Defaults[.pomodoroFocus]
            case .shortBreak: Defaults[.pomodoroShortBreak]
            case .longBreak: Defaults[.pomodoroLongBreak]
            }
            return TimeInterval(minutes * 60)
        }
    }

    @Published private(set) var phase: Phase = .focus
    /// Çalışıyorsa bitiş anı; duraklatılmış/boşta ise nil.
    @Published private(set) var endDate: Date?
    @Published private(set) var remainingWhenPaused: TimeInterval = Phase.focus.duration
    /// Mevcut döngüde tamamlanan odak oturumu sayısı.
    @Published private(set) var completedInCycle = 0
    @Published private(set) var completedToday = 0
    /// Bir aşama az önce bittiyse (canlı aktivite için kısa süre dolu kalır).
    @Published private(set) var justFinished: Phase?

    private var ticker: Timer?

    var isRunning: Bool { endDate != nil }
    /// Sayaç hiç başlatılmadıysa ya da sıfırlandıysa.
    var isIdle: Bool { endDate == nil && remainingWhenPaused == phase.duration }

    func remaining(at date: Date = .now) -> TimeInterval {
        if let endDate { return max(0, endDate.timeIntervalSince(date)) }
        return remainingWhenPaused
    }

    func progress(at date: Date = .now) -> Double {
        let total = phase.duration
        return total > 0 ? 1 - remaining(at: date) / total : 0
    }

    func toggle() { isRunning ? pause() : start() }

    func start() {
        guard !isRunning else { return }
        endDate = .now + remainingWhenPaused
        startTicker()
    }

    func pause() {
        guard let endDate else { return }
        remainingWhenPaused = max(0, endDate.timeIntervalSinceNow)
        self.endDate = nil
        stopTicker()
    }

    /// Mevcut aşamayı baştan başlatmadan sıfırlar.
    func reset() {
        endDate = nil
        remainingWhenPaused = phase.duration
        stopTicker()
    }

    /// Döngüyü tamamen sıfırlar.
    func resetCycle() {
        completedInCycle = 0
        phase = .focus
        reset()
    }

    /// Mevcut aşamayı bitmiş saymadan sonrakine geçer.
    func skip() {
        advance(countFocus: false)
    }

    /// Ayarlarda süre değişince boştaki sayacı güncelle.
    func durationsChanged() {
        if !isRunning { remainingWhenPaused = phase.duration }
    }

    private func startTicker() {
        guard ticker == nil else { return }
        ticker = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }

    private func tick() {
        guard let endDate, endDate <= .now else { return }
        let finished = phase
        if Defaults[.pomodoroPlaySound] {
            NSSound(named: finished == .focus ? "Glass" : "Hero")?.play()
        }
        justFinished = finished
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) { [weak self] in
            if self?.justFinished == finished { self?.justFinished = nil }
        }
        advance(countFocus: true)
        if Defaults[.pomodoroAutoStart] { start() }
    }

    private func advance(countFocus: Bool) {
        stopTicker()
        endDate = nil
        if phase == .focus {
            if countFocus {
                completedInCycle += 1
                completedToday += 1
            }
            phase = completedInCycle >= Defaults[.pomodoroSessionsBeforeLongBreak] ? .longBreak : .shortBreak
        } else {
            if phase == .longBreak { completedInCycle = 0 }
            phase = .focus
        }
        remainingWhenPaused = phase.duration
    }
}

struct PomodoroWidget: View {
    @ObservedObject private var store = PomodoroStore.shared
    @Default(.pomodoroSessionsBeforeLongBreak) private var sessions

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.height, proxy.size.width * 0.48)
            HStack(spacing: 12) {
                TimelineView(.periodic(from: .now, by: 0.5)) { ctx in
                    PomodoroRing(progress: store.progress(at: ctx.date),
                                 remaining: store.remaining(at: ctx.date),
                                 color: store.phase.color,
                                 isRunning: store.isRunning)
                }
                .frame(width: side, height: side)
                .onTapGesture { store.toggle() }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: store.phase.symbol)
                            .font(.system(size: 10, weight: .semibold))
                        Text(store.phase.title)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(store.phase.color)

                    // Döngüdeki odak oturumları
                    HStack(spacing: 4) {
                        ForEach(0..<sessions, id: \.self) { i in
                            Circle()
                                .fill(i < store.completedInCycle ? store.phase.color : .white.opacity(0.15))
                                .frame(width: 6, height: 6)
                        }
                    }

                    HStack(spacing: 2) {
                        NookButton(symbol: "arrow.counterclockwise", size: 26, fontSize: 11) { store.reset() }
                            .help("Sıfırla")
                        NookButton(symbol: store.isRunning ? "pause.fill" : "play.fill", size: 32, fontSize: 16) {
                            store.toggle()
                        }
                        NookButton(symbol: "forward.end.fill", size: 26, fontSize: 11) { store.skip() }
                            .help("Sonraki aşamaya geç")
                    }
                    .offset(x: -4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: .infinity)
        }
        .contextMenu {
            Button("Döngüyü sıfırla") { store.resetCycle() }
        }
    }
}

private struct PomodoroRing: View {
    let progress: Double
    let remaining: TimeInterval
    let color: Color
    let isRunning: Bool

    var body: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.1), lineWidth: 6)
            Circle()
                .trim(from: 0, to: max(0.001, progress))
                .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .opacity(progress > 0.002 ? 1 : 0)
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(isRunning ? 0.6 : 0), radius: 6)
                .animation(.linear(duration: 0.5), value: progress)
            Text(format(remaining))
                .font(.system(size: 17, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
                .contentTransition(.numericText(countsDown: true))
        }
        .padding(4)
    }

    private func format(_ t: TimeInterval) -> String {
        let s = Int(t.rounded(.up))
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
