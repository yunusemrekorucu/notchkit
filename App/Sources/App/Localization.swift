//
//  Localization.swift
//  NotchKit
//
//  NotchKit ships in English and Turkish. SwiftUI only translates string literals, but
//  most titles here travel as `String` values (settings rows, enum names, models), so the
//  overloads below look those up in Localizable.xcstrings too. They are disfavored like
//  SwiftUI's own `StringProtocol` initializers, so literals still go through
//  `LocalizedStringKey` and keep their interpolation.

import AppKit
import SwiftUI

/// The translation of `key` in the current language, or `key` itself when there is none.
func L(_ key: String) -> String {
    Bundle.main.localizedString(forKey: key, value: key, table: nil)
}

extension Text {
    @_disfavoredOverload
    init(_ content: String) {
        self.init(verbatim: L(content))
    }
}

extension Button where Label == Text {
    @_disfavoredOverload
    init(_ title: String, action: @escaping () -> Void) {
        self.init(action: action) { Text(verbatim: L(title)) }
    }

    @_disfavoredOverload
    init(_ title: String, role: ButtonRole?, action: @escaping () -> Void) {
        self.init(role: role, action: action) { Text(verbatim: L(title)) }
    }
}

extension Toggle where Label == Text {
    @_disfavoredOverload
    init(_ title: String, isOn: Binding<Bool>) {
        self.init(isOn: isOn) { Text(verbatim: L(title)) }
    }
}

extension Label where Title == Text, Icon == Image {
    @_disfavoredOverload
    init(_ title: String, systemImage: String) {
        self.init { Text(verbatim: L(title)) } icon: { Image(systemName: systemImage) }
    }
}

extension Picker where Label == Text {
    @_disfavoredOverload
    init(_ title: String, selection: Binding<SelectionValue>, @ViewBuilder content: () -> Content) {
        self.init(selection: selection, content: content) { Text(verbatim: L(title)) }
    }
}

extension Section where Parent == Text, Footer == EmptyView, Content: View {
    @_disfavoredOverload
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.init(content: content) { Text(verbatim: L(title)) }
    }
}

extension Menu where Label == Text {
    @_disfavoredOverload
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.init(content: content) { Text(verbatim: L(title)) }
    }
}

extension TextField where Label == Text {
    @_disfavoredOverload
    init(_ title: String, text: Binding<String>) {
        self.init(text: text, prompt: nil) { Text(verbatim: L(title)) }
    }
}

extension View {
    @_disfavoredOverload
    func help(_ text: String) -> some View {
        help(Text(verbatim: L(text)))
    }
}

// MARK: - App language

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case turkish = "tr"

    var id: String { rawValue }

    /// Language names stay in their own language so people can always find theirs.
    var title: String {
        switch self {
        case .system: L("System Default")
        case .english: "English"
        case .turkish: "Türkçe"
        }
    }

    /// The language chosen in NotchKit, read from the app's own `AppleLanguages` override.
    static var selected: AppLanguage {
        guard let id = Bundle.main.bundleIdentifier,
              let languages = UserDefaults.standard.persistentDomain(forName: id)?["AppleLanguages"] as? [String],
              let first = languages.first
        else { return .system }
        return first.hasPrefix("tr") ? .turkish : .english
    }

    func apply() {
        if self == .system {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([rawValue], forKey: "AppleLanguages")
        }
    }

    /// Bundle lookups are cached for the life of the process, so a new language needs a relaunch.
    static func relaunch() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        task.arguments = ["-c", "sleep 1; /usr/bin/open \"$0\"", Bundle.main.bundlePath]
        try? task.run()
        NSApp.terminate(nil)
    }
}

struct AppLanguageRow: View {
    @State private var selection = AppLanguage.selected
    private let launchLanguage = AppLanguage.selected

    var body: some View {
        HStack {
            SettingsRowLabel(
                title: "Language",
                description: "Choose the language NotchKit uses. NotchKit restarts to apply it."
            )
            Spacer()
            if selection != launchLanguage {
                Button("Restart to Apply") { AppLanguage.relaunch() }
                    .transition(.opacity)
            }
            Picker("", selection: $selection) {
                ForEach(AppLanguage.allCases) { language in
                    Text(verbatim: language.title).tag(language)
                }
            }
            .labelsHidden()
            .frame(width: 150)
        }
        .padding()
        .animation(.snappy(duration: 0.2), value: selection)
        .onChange(of: selection) { _, language in language.apply() }
    }
}
