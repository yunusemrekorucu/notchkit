import SwiftUI
import Defaults
import LaunchAtLogin

struct SettingsView: View {
    @ObservedObject private var nav = SettingsNavigation.shared

    var body: some View {
        TabView(selection: $nav.tab) {
            GeneralSettings().tabItem { Label("General", systemImage: "gear") }.tag(SettingsTab.general)
            NookSettings().tabItem { Label("Nook", systemImage: "lamp.desk.fill") }.tag(SettingsTab.nook)
            WidgetsSettings().tabItem { Label("Widgets", systemImage: "square.grid.2x2.fill") }.tag(SettingsTab.widgets)
            TraySettings().tabItem { Label("Tray", systemImage: "tray.fill") }.tag(SettingsTab.tray)
            LiveActivitySettings().tabItem { Label("Live Activities", systemImage: "clock.badge.fill") }
                .tag(SettingsTab.liveActivities)
            AboutSettings().tabItem { Label("About", systemImage: "ellipsis.circle.fill") }.tag(SettingsTab.about)
        }
        .frame(minWidth: 620, minHeight: 520)
    }
}

private struct GeneralSettings: View {
    @Default(.alwaysOpenNotchOnHover) private var openOnHover
    @Default(.disableHaptics) private var disableHaptics
    @Default(.preventUnhoverCloseWhenTyping) private var preventClose
    @Default(.preferRoundButtons) private var roundButtons
    @Default(.translucent) private var translucent
    @Default(.contentPadding) private var padding
    @Default(.notchWidthFineTune) private var widthTune
    @Default(.notchHeightFineTune) private var heightTune
    @Default(.horizontalSwipeChangesTrack) private var swipeTrack
    @State private var language = AppLanguage.current
    private let launchLanguage = AppLanguage.current

    var body: some View {
        Form {
            Section {
                Picker("Language", selection: $language) {
                    Text("System").tag(AppLanguage.system)
                    Text(verbatim: "English").tag(AppLanguage.english)
                    Text(verbatim: "Türkçe").tag(AppLanguage.turkish)
                }
                .onChange(of: language) { _, value in value.apply() }
                if language != launchLanguage {
                    HStack {
                        Text("Restart NotchKit to apply the new language.")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Restart Now") { AppLanguage.relaunch() }
                    }
                }
            } footer: {
                Text("System uses your Mac's language: Turkish if it's set to Turkish, English otherwise.")
            }
            Section {
                LaunchAtLogin.Toggle { Text("Launch at login") }
                Toggle("Always open on hover", isOn: $openOnHover)
                    .help("Some gestures are disabled while this is on.")
                Toggle("Disable haptic feedback", isOn: $disableHaptics)
                Toggle("Keep open while typing", isOn: $preventClose)
                Toggle("Swipe sideways to change tracks", isOn: $swipeTrack)
            }
            DisplaysSection()
            Section("Appearance") {
                Toggle("Prefer round buttons", isOn: $roundButtons)
                Toggle("Translucent notch background", isOn: $translucent)
                ValueStepper("Content padding", value: $padding, in: 4...24, display: "\(padding) pt")
            }
            Section {
                Slider(value: $widthTune, in: -20...20, step: 1) { Text("Width: \(Int(widthTune))") }
                Slider(value: $heightTune, in: -10...10, step: 1) { Text("Height: \(Int(heightTune))") }
                Button("Reset") { widthTune = 0; heightTune = 0 }
            } header: {
                Text("Notch fine-tuning")
            } footer: {
                Text("NotchKit detects your notch size automatically. If you see gaps at the edges, adjust it here.")
            }
        }
        .formStyle(.grouped)
    }
}

private struct DisplaysSection: View {
    @Default(.displayMode) private var mode
    @Default(.selectedDisplays) private var selected
    @State private var screens = NSScreen.screens

    var body: some View {
        Section {
            Picker("Show NotchKit on", selection: $mode) {
                Text("All displays").tag(DisplayMode.all)
                Text("Built-in display only").tag(DisplayMode.builtIn)
                Text("Main display only").tag(DisplayMode.primary)
                Text("Selected displays").tag(DisplayMode.custom)
            }
            ForEach(screens, id: \.displayUUID) { screen in
                Toggle(isOn: binding(for: screen)) {
                    Text(screen.localizedName)
                    Text(details(for: screen))
                }
                .disabled(isOnlyShown(screen))
            }
        } header: {
            Text("Displays")
        } footer: {
            Text("Turning a display on or off switches to Selected displays. If none of the chosen displays is connected, NotchKit uses the main display.")
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
            screens = NSScreen.screens
        }
    }

    private var shownIDs: Set<String> {
        return Set(DisplaySelection.screens().map(\.displayUUID))
    }

    private func isOnlyShown(_ screen: NSScreen) -> Bool {
        shownIDs == [screen.displayUUID]
    }

    private func binding(for screen: NSScreen) -> Binding<Bool> {
        Binding {
            shownIDs.contains(screen.displayUUID)
        } set: { isOn in
            var ids = shownIDs
            if isOn { ids.insert(screen.displayUUID) } else { ids.remove(screen.displayUUID) }
            // Keep choices for displays that are currently unplugged.
            let connected = Set(screens.map(\.displayUUID))
            let offline = mode == .custom ? selected.filter { !connected.contains($0) } : []
            selected = offline + screens.map(\.displayUUID).filter(ids.contains)
            mode = .custom
        }
    }

    private func details(for screen: NSScreen) -> String {
        var parts: [String] = []
        if screen == NSScreen.screens.first { parts.append(String(localized: "Main")) }
        if screen.isBuiltIn { parts.append(String(localized: "Built-in")) }
        if screen.hasNotch { parts.append(String(localized: "Notch")) }
        parts.append("\(Int(screen.frame.width))×\(Int(screen.frame.height))")
        return parts.joined(separator: " · ")
    }
}

private struct NookSettings: View {
    @Default(.nookEnabled) private var enabled
    @Default(.nookHeight) private var height
    @Default(.cellSize) private var cellSize
    @Default(.widgetsPadding) private var spacing
    @Default(.nookShowDividers) private var dividers

    var body: some View {
        Form {
            Section {
                Toggle("Enable the Nook", isOn: $enabled)
            } footer: {
                Text("When this is off, clicking the notch does nothing.")
            }
            Section {
                ValueStepper("Height", value: $height, in: 1...4, display: "\(height) cells")
                ValueStepper("Cell size", value: $cellSize, in: 40...80, step: 2, display: "\(cellSize) pt")
                ValueStepper("Widget spacing", value: $spacing, in: 4...20, display: "\(spacing) pt")
                Toggle("Show dividers between widgets", isOn: $dividers)
            } header: {
                Text("Layout")
            } footer: {
                Text("The width is calculated from the widgets in the Widgets tab.")
            }
            Section {
                Button("Edit Widgets…") { SettingsNavigation.shared.tab = .widgets }
            }
        }
        .formStyle(.grouped)
    }
}

private struct TraySettings: View {
    @Default(.trayWidth) private var width
    @Default(.trayHeight) private var height
    @ObservedObject private var tray = TrayStore.shared

    var body: some View {
        Form {
            Section("Size") {
                ValueStepper("Width", value: $width, in: 6...20, display: "\(width) cells")
                ValueStepper("Height", value: $height, in: 1...4, display: "\(height) cells")
            }
            Section("Files") {
                LabeledContent("Files in tray", value: "\(tray.items.count)")
                Button("Clear Tray", role: .destructive) { tray.removeAll() }.disabled(tray.items.isEmpty)
            }
        }
        .formStyle(.grouped)
    }
}

private struct LiveActivitySettings: View {
    @Default(.liveActivitiesEnabled) private var enabled
    @Default(.enabledLiveActivities) private var activities
    @Default(.enableQuickPeek) private var quickPeek
    @Default(.coloredEffects) private var colored

    var body: some View {
        Form {
            Section {
                Toggle("Enable live activities", isOn: $enabled)
                Toggle("Show a quick peek when the song changes", isOn: $quickPeek)
            }
            Section("Activities") {
                ForEach(LiveActivityToggle.allCases) { a in
                    Toggle(a.title, isOn: Binding(
                        get: { activities.contains(a) },
                        set: { on in if on { activities.append(a) } else { activities.removeAll { $0 == a } } }))
                }
            }
            Section("Media") {
                Toggle("Use album colors", isOn: $colored)
            }
        }
        .formStyle(.grouped)
    }
}

private struct AboutSettings: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 96, height: 96)
            Text(verbatim: "NotchKit").font(.largeTitle.bold())
            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .foregroundStyle(.secondary)
            Text("Music, notes, tasks and files, right inside your notch.")
                .multilineTextAlignment(.center).foregroundStyle(.secondary)
            Text("Media: mediaremote-adapter (BSD-3, © Jonas van den Berg)")
                .font(.caption).foregroundStyle(.tertiary)
            Button("Quit NotchKit") { NSApp.terminate(nil) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
