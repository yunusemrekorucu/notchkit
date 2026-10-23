//
//  ProductivityStores.swift
//  NotchKit
//
//  State for the Pomodoro, To-dos and Quick Apps widgets. They keep NotchKit 1.x's
//  UserDefaults keys and value formats, so existing tasks, pinned apps and durations
//  carry over.

import AppKit
import Combine
import SwiftUI

// MARK: - Pomodoro

/// Focus → short break → … → long break cycle.
@MainActor
final class PomodoroManager: ObservableObject {
    static let shared = PomodoroManager()

    enum Phase: Equatable {
        case focus, shortBreak, longBreak

        var title: String {
            switch self {
            case .focus: "Focus"
            case .shortBreak: "Short Break"
            case .longBreak: "Long Break"
            }
        }

        var symbol: String {
            switch self {
            case .focus: "target"
            case .shortBreak: "cup.and.saucer.fill"
            case .longBreak: "figure.walk"
            }
        }

        var colors: [Color] {
            switch self {
            case .focus: [.red, .orange, .pink]
            case .shortBreak: [.green, .mint, .teal]
            case .longBreak: [.blue, .cyan, .indigo]
            }
        }

        var accent: Color { colors[0] }
    }

    enum Key {
        static let focus = "pomodoroFocus"
        static let shortBreak = "pomodoroShortBreak"
        static let longBreak = "pomodoroLongBreak"
        static let sessions = "pomodoroSessionsBeforeLongBreak"
        static let autoStart = "pomodoroAutoStart"
        static let playSound = "pomodoroPlaySound"
    }

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            Key.focus: 25, Key.shortBreak: 5, Key.longBreak: 15,
            Key.sessions: 4, Key.autoStart: false, Key.playSound: true
        ])
    }

    @Published private(set) var phase: Phase = .focus
    /// End of the running phase; nil while paused or idle.
    @Published private(set) var endDate: Date?
    @Published private(set) var remainingWhenPaused: TimeInterval = 0
    /// Focus sessions finished in the current cycle.
    @Published private(set) var completedInCycle = 0
    @Published private(set) var completedToday = 0
    /// Set briefly when a phase ends so the live activity can announce it.
    @Published private(set) var justFinished: Phase?

    private var ticker: Timer?
    private var completedDay = Calendar.current.startOfDay(for: .now)

    private init() {
        Self.registerDefaults()
        remainingWhenPaused = duration(of: .focus)
    }

    var sessionsBeforeLongBreak: Int { max(1, UserDefaults.standard.integer(forKey: Key.sessions)) }
    var isRunning: Bool { endDate != nil }
    var isIdle: Bool { endDate == nil && remainingWhenPaused == duration(of: phase) }
    var isActive: Bool { !isIdle }

    func duration(of phase: Phase) -> TimeInterval {
        let key = switch phase {
        case .focus: Key.focus
        case .shortBreak: Key.shortBreak
        case .longBreak: Key.longBreak
        }
        return TimeInterval(max(1, UserDefaults.standard.integer(forKey: key)) * 60)
    }

    func remaining(at date: Date = .now) -> TimeInterval {
        if let endDate { return max(0, endDate.timeIntervalSince(date)) }
        return remainingWhenPaused
    }

    func progress(at date: Date = .now) -> Double {
        let total = duration(of: phase)
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

    /// Restarts the current phase.
    func reset() {
        endDate = nil
        remainingWhenPaused = duration(of: phase)
        stopTicker()
    }

    func resetCycle() {
        completedInCycle = 0
        phase = .focus
        reset()
    }

    /// Moves to the next phase without counting the current one as finished.
    func skip() { advance(countFocus: false) }

    /// Picks up new durations from settings while idle.
    func durationsChanged() {
        if !isRunning { remainingWhenPaused = duration(of: phase) }
    }

    static func format(_ interval: TimeInterval) -> String {
        let seconds = Int(interval.rounded(.up))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
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
        if UserDefaults.standard.bool(forKey: Key.playSound) {
            NSSound(named: finished == .focus ? "Glass" : "Hero")?.play()
        }
        justFinished = finished
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) { [weak self] in
            if self?.justFinished == finished { self?.justFinished = nil }
        }
        advance(countFocus: true)
        if UserDefaults.standard.bool(forKey: Key.autoStart) { start() }
    }

    private func advance(countFocus: Bool) {
        stopTicker()
        endDate = nil
        if phase == .focus {
            if countFocus {
                let today = Calendar.current.startOfDay(for: .now)
                if today != completedDay {
                    completedDay = today
                    completedToday = 0
                }
                completedInCycle += 1
                completedToday += 1
            }
            phase = completedInCycle >= sessionsBeforeLongBreak ? .longBreak : .shortBreak
        } else {
            if phase == .longBreak { completedInCycle = 0 }
            phase = .focus
        }
        remainingWhenPaused = duration(of: phase)
    }
}

// MARK: - To-dos

struct TodoItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var isCompleted = false
    var isPriority = false
    var createdAt = Date()
}

@MainActor
final class TodoStore: ObservableObject {
    static let shared = TodoStore()

    private static let itemsKey = "todos"
    static let showCompletedKey = "showCompletedTodos"

    @Published private(set) var items: [TodoItem] = []

    private init() {
        UserDefaults.standard.register(defaults: [Self.showCompletedKey: true])
        items = Self.load()
    }

    var showCompleted: Bool { UserDefaults.standard.bool(forKey: Self.showCompletedKey) }
    var openCount: Int { items.filter { !$0.isCompleted }.count }

    /// Open tasks first, starred before the rest, oldest first within each group.
    var sorted: [TodoItem] {
        items
            .filter { showCompleted || !$0.isCompleted }
            .sorted {
                ($0.isCompleted ? 1 : 0, $0.isPriority ? 0 : 1, $0.createdAt)
                    < ($1.isCompleted ? 1 : 0, $1.isPriority ? 0 : 1, $1.createdAt)
            }
    }

    func add(_ title: String) {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        items.append(TodoItem(title: title))
        save()
    }

    func toggleCompleted(_ item: TodoItem) { update(item) { $0.isCompleted.toggle() } }
    func togglePriority(_ item: TodoItem) { update(item) { $0.isPriority.toggle() } }

    func delete(_ item: TodoItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func clearCompleted() {
        items.removeAll(where: \.isCompleted)
        save()
    }

    private func update(_ item: TodoItem, _ change: (inout TodoItem) -> Void) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        change(&items[index])
        save()
    }

    // NotchKit 1.x stored each task as its own JSON string inside an array.
    private static func load() -> [TodoItem] {
        let decoder = JSONDecoder()
        let raw = UserDefaults.standard.array(forKey: itemsKey) as? [String] ?? []
        return raw.compactMap { try? decoder.decode(TodoItem.self, from: Data($0.utf8)) }
    }

    private func save() {
        let encoder = JSONEncoder()
        let raw = items.compactMap { try? encoder.encode($0) }.compactMap { String(data: $0, encoding: .utf8) }
        UserDefaults.standard.set(raw, forKey: Self.itemsKey)
    }
}

// MARK: - Quick Apps

@MainActor
final class QuickAppsStore: ObservableObject {
    static let shared = QuickAppsStore()

    private static let appsKey = "quickApps"

    @Published private(set) var paths: [String]
    @Published private(set) var runningBundleIDs: Set<String> = []

    private var observers: [NSObjectProtocol] = []

    private init() {
        paths = UserDefaults.standard.stringArray(forKey: Self.appsKey) ?? []
        refreshRunning()
        let center = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.didLaunchApplicationNotification, NSWorkspace.didTerminateApplicationNotification] {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.refreshRunning() }
            })
        }
    }

    var urls: [URL] { paths.map { URL(fileURLWithPath: $0) } }

    func isRunning(_ url: URL) -> Bool {
        guard let id = Bundle(url: url)?.bundleIdentifier else { return false }
        return runningBundleIDs.contains(id)
    }

    func add(_ urls: [URL]) {
        for url in urls where url.pathExtension == "app" && !paths.contains(url.path) {
            paths.append(url.path)
        }
        save()
    }

    func remove(_ url: URL) {
        paths.removeAll { $0 == url.path }
        save()
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        paths.move(fromOffsets: source, toOffset: destination)
        save()
    }

    func launch(_ url: URL) {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: configuration)
    }

    func pickApps() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = true
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.prompt = "Add"
        if panel.runModal() == .OK { add(panel.urls) }
    }

    static func displayName(_ url: URL) -> String {
        FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
    }

    private func refreshRunning() {
        runningBundleIDs = Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
    }

    private func save() {
        UserDefaults.standard.set(paths, forKey: Self.appsKey)
    }
}
