//
//  LegacyNotchKitMigration.swift
//  NotchKit
//
//  NotchKit 1.x kept its widget list in the "nookWidgets" default. The first time
//  NotchKit 2 runs, turn on the matching widgets so the notch shows what it did before.

import Foundation

@MainActor
enum LegacyNotchKitMigration {
    private static let doneKey = "notchKit2WidgetsMigrated"

    static func runIfNeeded(_ model: SettingsModel) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: doneKey) else { return }
        defaults.set(true, forKey: doneKey)

        // Defaults stored each entry as a JSON string, e.g. "\"media\"".
        guard let raw = defaults.array(forKey: "nookWidgets") as? [String] else { return }
        let widgets = Set(raw.map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\"")) })

        var settings = model.settings
        settings.musicWidgetEnabled = widgets.contains("media")
        settings.calendarWidgetEnabled = widgets.contains("calendar")
        settings.shortcutsWidgetEnabled = widgets.contains("shortcuts")
        settings.mirrorWidgetEnabled = widgets.contains("mirror")
        settings.notesWidgetEnabled = widgets.contains("notes")
        settings.todoWidgetEnabled = widgets.contains("todo")
        settings.pomodoroWidgetEnabled = widgets.contains("pomodoro")
        settings.quickAppsWidgetEnabled = widgets.contains("quickApps")

        // Bring the carried-over widgets forward so they fit before the newer ones.
        let carried: [WidgetType] = [.todo, .pomodoro, .quickApps].filter { widgets.contains($0.rawValue) }
        var order = settings.widgetOrder.filter { !carried.contains($0) }
        let anchor = order.firstIndex(of: .calendar).map { $0 + 1 } ?? order.count
        order.insert(contentsOf: carried, at: anchor)
        settings.widgetOrder = order
        model.settings = settings
    }
}
