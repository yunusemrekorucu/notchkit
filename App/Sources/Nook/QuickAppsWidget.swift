import SwiftUI
import AppKit
import Defaults
import UniformTypeIdentifiers

/// Sabitlenen uygulamalar ve çalışma durumları.
@MainActor
final class QuickAppsStore: ObservableObject {
    static let shared = QuickAppsStore()

    @Published private(set) var runningBundleIDs: Set<String> = []

    init() {
        refreshRunning()
        let center = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.didLaunchApplicationNotification, NSWorkspace.didTerminateApplicationNotification] {
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.refreshRunning() }
            }
        }
    }

    private func refreshRunning() {
        runningBundleIDs = Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
    }

    func isRunning(_ url: URL) -> Bool {
        guard let id = Bundle(url: url)?.bundleIdentifier else { return false }
        return runningBundleIDs.contains(id)
    }

    func add(_ urls: [URL]) {
        let apps = urls.filter { $0.pathExtension == "app" }.map(\.path)
        for path in apps where !Defaults[.quickApps].contains(path) {
            Defaults[.quickApps].append(path)
        }
    }

    func remove(_ path: String) {
        Defaults[.quickApps].removeAll { $0 == path }
    }

    func launch(_ url: URL) {
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: config)
    }

    /// Ayarlarda uygulama seçmek için.
    func pickApps() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = true
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.prompt = "Ekle"
        if panel.runModal() == .OK { add(panel.urls) }
    }

    static func displayName(_ url: URL) -> String {
        FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
    }
}

struct QuickAppsWidget: View {
    @Default(.quickApps) private var apps
    @ObservedObject private var store = QuickAppsStore.shared
    @State private var targeted = false

    /// Uygulamalar 2 satırlı sütunlara bölünür; widget genişliği sütun sayısıyla büyür.
    private var columns: [[String]] {
        stride(from: 0, to: apps.count, by: 2).map { Array(apps[$0..<min($0 + 2, apps.count)]) }
    }

    var body: some View {
        Group {
            if apps.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "plus.app")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white.opacity(targeted ? 1 : 0.6))
                    Text("Uygulama sürükle")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                        .foregroundStyle(.white.opacity(targeted ? 0.6 : 0.2)))
                .contentShape(Rectangle())
                .onTapGesture { SettingsOpener.open(tab: .widgets, widget: .quickApps) }
            } else {
                HStack(spacing: 0) {
                    ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                        VStack(spacing: 0) {
                            ForEach(column, id: \.self) { path in
                                QuickAppIcon(url: URL(fileURLWithPath: path),
                                             isRunning: store.isRunning(URL(fileURLWithPath: path)))
                            }
                            if column.count == 1 { Spacer(minLength: 0) }
                        }
                        .frame(width: NookLayout.unit)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $targeted) { providers in
            loadFileURLs(from: providers) { store.add($0) }
            return true
        }
    }
}

private struct QuickAppIcon: View {
    let url: URL
    let isRunning: Bool
    @State private var hovering = false

    var body: some View {
        VStack(spacing: 2) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                .resizable()
                .interpolation(.high)
                .frame(width: 38, height: 38)
                .scaleEffect(hovering ? 1.12 : 1)
                .shadow(color: .black.opacity(0.4), radius: hovering ? 4 : 0, y: 2)
            Circle()
                .fill(.white.opacity(isRunning ? 0.7 : 0))
                .frame(width: 3, height: 3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onHover { h in withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { hovering = h } }
        .onTapGesture { QuickAppsStore.shared.launch(url) }
        .help(QuickAppsStore.displayName(url))
        .contextMenu {
            Button("Aç") { QuickAppsStore.shared.launch(url) }
            Button("Finder'da göster") { NSWorkspace.shared.activateFileViewerSelecting([url]) }
            Divider()
            Button("Kaldır", role: .destructive) { QuickAppsStore.shared.remove(url.path) }
        }
    }
}
