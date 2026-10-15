import AppKit
import Defaults

/// Which connected displays get a notch panel, based on the Displays setting.
enum DisplaySelection {
    static func screens() -> [NSScreen] {
        let all = NSScreen.screens
        let chosen: [NSScreen]
        switch Defaults[.displayMode] {
        case .all:
            chosen = all
        case .builtIn:
            chosen = all.filter(\.isBuiltIn)
        case .primary:
            chosen = Array(all.prefix(1))
        case .custom:
            let selected = Set(Defaults[.selectedDisplays])
            chosen = all.filter { selected.contains($0.displayUUID) }
        }
        // Never leave the app without a notch: fall back to the menu bar display
        // (e.g. "Built-in only" with the lid closed, or a selected monitor unplugged).
        return chosen.isEmpty ? Array(all.prefix(1)) : chosen
    }

    /// Older versions had a single "Enable on screens without a notch" switch.
    static func migrateLegacySetting() {
        let defaults = UserDefaults.standard
        let legacyKey = "enableOnNonNotchScreens"
        guard defaults.object(forKey: legacyKey) != nil else { return }
        // `object(forKey:)` would also see the registered default, so look at what was actually saved.
        let saved = defaults.persistentDomain(forName: Bundle.main.bundleIdentifier ?? "") ?? [:]
        if saved[Defaults.Keys.displayMode.name] == nil, !defaults.bool(forKey: legacyKey) {
            Defaults[.displayMode] = .builtIn
        }
        defaults.removeObject(forKey: legacyKey)
    }
}

extension NSScreen {
    /// Stays the same across reconnects and restarts, unlike `displayID`.
    var displayUUID: String {
        guard let uuid = CGDisplayCreateUUIDFromDisplayID(displayID)?.takeRetainedValue() else {
            return String(displayID)
        }
        return CFUUIDCreateString(nil, uuid) as String
    }

    var isBuiltIn: Bool { CGDisplayIsBuiltin(displayID) != 0 }

    var hasNotch: Bool { safeAreaInsets.top > 0 }
}
