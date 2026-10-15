import Foundation

/// The app used to ship as "Nook" (com.yunusemrekorucu.Nook). On first launch as NotchKit,
/// copy its settings and tray files over so nothing is lost.
enum LegacyMigration {
    private static let legacyBundleID = "com.yunusemrekorucu.Nook"
    private static let flagKey = "migratedFromLegacyNook"

    static func run() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: flagKey) else { return }
        defaults.set(true, forKey: flagKey)

        if let legacy = defaults.persistentDomain(forName: legacyBundleID) {
            for (key, value) in legacy where defaults.persistentDomain(forName: Bundle.main.bundleIdentifier ?? "")?[key] == nil {
                // Window frames belong to the old app's windows.
                guard !key.hasPrefix("NSWindow Frame") else { continue }
                defaults.set(value, forKey: key)
            }
        }

        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let oldTray = support.appendingPathComponent(legacyBundleID).appendingPathComponent("TrayFiles")
        let newTray = support.appendingPathComponent(Bundle.main.bundleIdentifier ?? "NotchKit").appendingPathComponent("TrayFiles")
        guard let files = try? FileManager.default.contentsOfDirectory(at: oldTray, includingPropertiesForKeys: nil),
              !files.isEmpty else { return }
        try? FileManager.default.createDirectory(at: newTray, withIntermediateDirectories: true)
        for file in files {
            try? FileManager.default.moveItem(at: file, to: newTray.appendingPathComponent(file.lastPathComponent))
        }
    }
}
