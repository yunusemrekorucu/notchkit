import AppKit
import Combine

struct TrayItem: Identifiable, Hashable, Codable {
    var id = UUID()
    var url: URL
    var name: String { url.lastPathComponent }
}

/// Tepsiye bırakılan dosyalar Application Support/TrayFiles altına kopyalanır, uygulama yeniden açıldığında korunur.
@MainActor
final class TrayStore: ObservableObject {
    static let shared = TrayStore()

    @Published private(set) var items: [TrayItem] = []

    private let directory: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(Bundle.main.bundleIdentifier ?? "Nook")
            .appendingPathComponent("TrayFiles")
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }()

    func load() {
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: [.creationDateKey], options: [.skipsHiddenFiles])) ?? []
        items = urls
            .sorted { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }
            .map { TrayItem(url: $0) }
    }

    func add(_ urls: [URL]) {
        for url in urls {
            var target = directory.appendingPathComponent(url.lastPathComponent)
            var counter = 2
            while FileManager.default.fileExists(atPath: target.path) {
                let base = url.deletingPathExtension().lastPathComponent
                let ext = url.pathExtension
                target = directory.appendingPathComponent(ext.isEmpty ? "\(base) \(counter)" : "\(base) \(counter).\(ext)")
                counter += 1
            }
            do {
                try FileManager.default.copyItem(at: url, to: target)
                items.append(TrayItem(url: target))
            } catch {
                NSLog("Tepsiye eklenemedi: \(error)")
            }
        }
    }

    func remove(_ item: TrayItem) {
        try? FileManager.default.removeItem(at: item.url)
        items.removeAll { $0.id == item.id }
    }

    func removeAll() {
        items.forEach { try? FileManager.default.removeItem(at: $0.url) }
        items.removeAll()
    }

    func open(_ item: TrayItem) { NSWorkspace.shared.open(item.url) }
    func reveal(_ item: TrayItem) { NSWorkspace.shared.activateFileViewerSelecting([item.url]) }

    func airDrop(_ urls: [URL]) {
        NSSharingService(named: .sendViaAirDrop)?.perform(withItems: urls)
    }
}

private extension URL {
    var creationDate: Date? { (try? resourceValues(forKeys: [.creationDateKey]))?.creationDate }
}
