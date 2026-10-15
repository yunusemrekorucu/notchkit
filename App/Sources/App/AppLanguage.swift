import AppKit

/// Interface language. "System" follows the Mac's preferred languages (Turkish if Turkish
/// is preferred, English otherwise). An explicit choice is stored in the app's own
/// `AppleLanguages` override and takes effect after a restart.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system, english, turkish

    var id: String { rawValue }

    private var code: String? {
        switch self {
        case .system: nil
        case .english: "en"
        case .turkish: "tr"
        }
    }

    static var current: AppLanguage {
        guard let override = UserDefaults.standard.persistentDomain(forName: Bundle.main.bundleIdentifier ?? "")?["AppleLanguages"] as? [String],
              let first = override.first else { return .system }
        return first.hasPrefix("tr") ? .turkish : .english
    }

    func apply() {
        if let code {
            UserDefaults.standard.set([code], forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
    }

    /// Language the app is actually running in right now.
    static var active: String { Bundle.main.preferredLocalizations.first ?? "en" }

    static func relaunch() {
        let path = Bundle.main.bundlePath
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        task.arguments = ["-c", "sleep 0.5; /usr/bin/open \"\(path)\""]
        try? task.run()
        NSApp.terminate(nil)
    }
}
