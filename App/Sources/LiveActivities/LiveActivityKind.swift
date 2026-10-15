import SwiftUI
import Defaults

/// Kapalı notch'un iki yanında gösterilen canlı aktiviteler (öncelik sırasıyla).
enum LiveActivityKind: Equatable {
    case charging
    case media
    case tray
    case calendar
    /// Pomodoro çalışırken geri sayım; bir aşama bitince "bitti" bildirimi.
    case pomodoro

    /// Notch'un her iki yanına eklenecek genişlik.
    var extraWidth: CGFloat {
        switch self {
        case .media: 34
        case .charging: 44
        case .tray: 30
        case .calendar: 56
        case .pomodoro: 50
        }
    }

    /// Hızlı bakışta notch'un aşağı doğru uzama miktarı.
    var peekHeight: CGFloat {
        switch self {
        case .media: 30
        default: 0
        }
    }

    @MainActor
    static func current(quickPeek: LiveActivityKind?) -> LiveActivityKind? {
        guard Defaults[.liveActivitiesEnabled] else { return nil }
        if let quickPeek { return quickPeek }
        let enabled = Set(Defaults[.enabledLiveActivities])
        let pomodoro = PomodoroStore.shared
        if enabled.contains(.pomodoro), pomodoro.justFinished != nil { return .pomodoro }
        if enabled.contains(.battery), BatteryMonitor.shared.showChargingActivity { return .charging }
        if enabled.contains(.pomodoro), pomodoro.isRunning { return .pomodoro }
        if enabled.contains(.media), MediaController.shared.isActive { return .media }
        if enabled.contains(.calendar), CalendarStore.shared.upcoming != nil { return .calendar }
        if enabled.contains(.tray), !TrayStore.shared.items.isEmpty { return .tray }
        return nil
    }
}
