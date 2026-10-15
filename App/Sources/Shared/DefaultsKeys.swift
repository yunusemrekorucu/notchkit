import SwiftUI
import Defaults

enum MediaSource: String, CaseIterable, Defaults.Serializable { case systemWide, appleMusic, spotify }
enum FullscreenMode: String, CaseIterable, Defaults.Serializable { case allMonitors, notchedScreens, never }
enum MediaEffect: String, CaseIterable, Defaults.Serializable { case spectrograph, waves, vibratingCircle }

struct TodoItem: Identifiable, Codable, Hashable, Defaults.Serializable {
    var id = UUID()
    var title: String
    var isCompleted = false
    var isPriority = false
    var createdAt = Date()
}

struct Note: Identifiable, Codable, Hashable, Defaults.Serializable {
    var id = UUID()
    var text: String
    var icon: String = "note.text"
    var updatedAt = Date()
}

enum NookWidget: String, CaseIterable, Identifiable, Codable, Defaults.Serializable {
    case media, calendar, shortcuts, mirror, notes, todo, pomodoro, quickApps
    var id: String { rawValue }

    var title: String {
        switch self {
        case .media: String(localized: "Media Player")
        case .calendar: String(localized: "Calendar")
        case .shortcuts: String(localized: "Shortcuts")
        case .mirror: String(localized: "Mirror")
        case .notes: String(localized: "Notes")
        case .todo: String(localized: "To-dos")
        case .pomodoro: String(localized: "Pomodoro")
        case .quickApps: String(localized: "Quick Apps")
        }
    }

    var symbol: String {
        switch self {
        case .media: "play.circle.fill"
        case .calendar: "calendar"
        case .shortcuts: "circle.grid.2x2.fill"
        case .mirror: "web.camera.fill"
        case .notes: "note.text"
        case .todo: "checklist"
        case .pomodoro: "timer"
        case .quickApps: "square.grid.3x3.fill"
        }
    }

    /// Varsayılan genişlik (hücre).
    var defaultWidth: Int {
        switch self {
        case .media: 5
        case .calendar: 5
        case .shortcuts: 2
        case .mirror: 2
        case .notes: 3
        case .todo: 3
        case .pomodoro: 4
        case .quickApps: 2
        }
    }

    /// Kestirmeler ve Hızlı Uygulamalar genişliği içeriğe göre otomatik hesaplanır.
    var isAutoWidth: Bool { self == .shortcuts || self == .quickApps }

    /// Geçerli genişlik (hücre).
    var width: Int {
        if self == .shortcuts {
            let count = Defaults[.shortcutsToDisplay].count
            guard count > 0 else { return 2 }
            // Her sütunda 2 kestirme bulunur.
            return Int((Double(count) / 2).rounded(.up)) * Defaults[.shortcutColumnWidth]
        }
        if self == .quickApps {
            // Her sütunda 2 uygulama, sütun başına 1 hücre.
            return max(2, Int((Double(Defaults[.quickApps].count) / 2).rounded(.up)))
        }
        return Defaults[.widgetWidths][rawValue] ?? defaultWidth
    }

    func setWidth(_ value: Int) {
        Defaults[.widgetWidths][rawValue] = value
    }

    /// Ayarlardaki önizleme ve kartlar için vurgu rengi.
    var tint: Color {
        switch self {
        case .media: .indigo
        case .calendar: .red
        case .shortcuts: .purple
        case .mirror: .teal
        case .notes: .yellow
        case .todo: .green
        case .pomodoro: .orange
        case .quickApps: .blue
        }
    }
}

enum LiveActivityToggle: String, CaseIterable, Identifiable, Codable, Defaults.Serializable {
    case media, tray, calendar, bluetooth, battery, pomodoro
    var id: String { rawValue }
    var title: String {
        switch self {
        case .media: String(localized: "Now Playing")
        case .tray: String(localized: "Tray files")
        case .calendar: String(localized: "Upcoming event")
        case .bluetooth: String(localized: "Bluetooth device")
        case .battery: String(localized: "Battery")
        case .pomodoro: String(localized: "Pomodoro")
        }
    }
}

extension Defaults.Keys {
    // Genel
    static let alwaysOpenNotchOnHover = Key<Bool>("alwaysOpenNotchOnHover", default: false)
    static let contentPadding = Key<Int>("contentPadding", default: 12)
    static let disableHaptics = Key<Bool>("disableHaptics", default: false)
    static let enableOnNonNotchScreens = Key<Bool>("enableOnNonNotchScreens", default: true)
    static let notchWidthFineTune = Key<CGFloat>("notchWidthFineTune", default: 0)
    static let notchHeightFineTune = Key<CGFloat>("notchHeightFineTune", default: 0)
    static let preferRoundButtons = Key<Bool>("preferRoundButtons", default: true)
    static let preferredMediaSource = Key<MediaSource>("preferredMediaSource", default: .systemWide)
    static let preventUnhoverCloseWhenTyping = Key<Bool>("preventUnhoverCloseWhenTyping", default: true)
    static let showInFullscreen = Key<FullscreenMode>("showInFullscreen", default: .notchedScreens)
    static let translucent = Key<Bool>("translucent", default: false)

    // Nook
    static let nookEnabled = Key<Bool>("nookEnabled", default: true)
    static let nookWidgets = Key<[NookWidget]>("nookWidgets", default: [.media, .shortcuts, .mirror, .notes])
    static let nookShowDividers = Key<Bool>("nookShowDividers", default: true)
    static let widgetWidths = Key<[String: Int]>("widgetWidths", default: [:])
    static let nookHeight = Key<Int>("nookHeight", default: 2)
    static let widgetsPadding = Key<Int>("widgetsPadding", default: 12)
    static let cellSize = Key<Int>("cellSize", default: 54)

    // Tray
    static let trayWidth = Key<Int>("trayWidth", default: 12)
    static let trayHeight = Key<Int>("trayHeight", default: 2)

    // Canlı aktiviteler
    static let liveActivitiesEnabled = Key<Bool>("liveActivitiesEnabled", default: true)
    static let enabledLiveActivities = Key<[LiveActivityToggle]>("enabledLiveActivities", default: [.media, .tray, .calendar, .bluetooth, .battery, .pomodoro])
    static let enableQuickPeek = Key<Bool>("enableQuickPeek", default: false)
    static let inactivityTimeout = Key<Int>("inactivityTimeout", default: 10)

    // Takvim
    static let calendarDaysAhead = Key<Int>("calendarDaysAhead", default: 7)
    static let calendarShowAllDay = Key<Bool>("calendarShowAllDay", default: false)
    static let selectedCalendars = Key<[String]>("selectedCalendars", default: [])

    // Medya canlı aktivitesi
    static let mediaEffect = Key<MediaEffect>("mediaEffect", default: .spectrograph)
    static let coloredEffects = Key<Bool>("coloredEffects", default: true)
    static let albumCornerRadius = Key<Double>("albumCornerRadius", default: 6)
    static let horizontalSwipeChangesTrack = Key<Bool>("horizontalSwipeChangesTrack", default: true)
    static let lockWhenTyping = Key<Bool>("lockWhenTyping", default: false)

    // Yapılacaklar / notlar
    static let todos = Key<[TodoItem]>("todos", default: [])
    static let showCompletedTodos = Key<Bool>("showCompletedTodos", default: true)
    static let notes = Key<[Note]>("notes", default: [Note(text: "")])

    // Pomodoro (dakika)
    static let pomodoroFocus = Key<Int>("pomodoroFocus", default: 25)
    static let pomodoroShortBreak = Key<Int>("pomodoroShortBreak", default: 5)
    static let pomodoroLongBreak = Key<Int>("pomodoroLongBreak", default: 15)
    static let pomodoroSessionsBeforeLongBreak = Key<Int>("pomodoroSessionsBeforeLongBreak", default: 4)
    static let pomodoroAutoStart = Key<Bool>("pomodoroAutoStart", default: false)
    static let pomodoroPlaySound = Key<Bool>("pomodoroPlaySound", default: true)

    // Hızlı uygulamalar (uygulama dosya yolları)
    static let quickApps = Key<[String]>("quickApps", default: [])

    // Kestirmeler
    static let shortcutsToDisplay = Key<[String]>("shortcutsToDisplay", default: [])
    /// Bir kestirme sütununun genişliği (hücre).
    static let shortcutColumnWidth = Key<Int>("shortcutColumnWidth", default: 2)

    // Ayna
    static let mirrorDeviceID = Key<String?>("mirrorDeviceID")
}
