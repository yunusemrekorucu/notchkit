import AppKit
import Combine

/// Açık kaynak mediaremote-adapter (BSD-3) üzerinden sistem genelindeki "Şimdi Çalıyor" bilgisini okur.
/// /usr/bin/perl, özel MediaRemote framework'ünü kullanma yetkisine sahip olduğu için köprü olarak kullanılır.
@MainActor
final class MediaController: ObservableObject {
    static let shared = MediaController()

    @Published private(set) var nowPlaying = NowPlaying()

    enum Command: Int {
        case play = 0, pause, togglePlayPause, stop, nextTrack, previousTrack,
             toggleShuffle, toggleRepeat, startForwardSeek, endForwardSeek,
             startBackwardSeek, endBackwardSeek, goBackFifteen, skipFifteen
    }

    private var process: Process?
    private var buffer = Data()
    private var state: [String: Any] = [:]
    private var restartWork: DispatchWorkItem?

    private var adapterDir: URL? {
        Bundle.main.resourceURL?.appendingPathComponent("MediaRemoteAdapter")
    }
    private var scriptURL: URL? { adapterDir?.appendingPathComponent("mediaremote-adapter.pl") }
    private var frameworkURL: URL? { adapterDir?.appendingPathComponent("MediaRemoteAdapter.framework") }

    func start() {
        guard process == nil, let script = scriptURL, let framework = frameworkURL,
              FileManager.default.fileExists(atPath: script.path) else { return }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
        p.arguments = [script.path, framework.path, "stream", "--micros", "--debounce=50"]
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = FileHandle.nullDevice
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            Task { @MainActor in self?.consume(data) }
        }
        p.terminationHandler = { [weak self] _ in
            Task { @MainActor in self?.handleTermination() }
        }
        do {
            try p.run()
            process = p
        } catch {
            NSLog("MediaRemoteAdapter başlatılamadı: \(error)")
        }
    }

    func stop() {
        restartWork?.cancel()
        process?.terminationHandler = nil
        process?.terminate()
        process = nil
    }

    private func handleTermination() {
        process = nil
        let work = DispatchWorkItem { [weak self] in Task { @MainActor in self?.start() } }
        restartWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: work)
    }

    private func consume(_ data: Data) {
        buffer.append(data)
        while let newline = buffer.firstIndex(of: 0x0A) {
            let line = buffer[buffer.startIndex..<newline]
            buffer.removeSubrange(buffer.startIndex...newline)
            guard !line.isEmpty,
                  let object = try? JSONSerialization.jsonObject(with: line) as? [String: Any],
                  let payload = object["payload"] as? [String: Any] else { continue }
            if (object["diff"] as? Bool) == true {
                for (key, value) in payload {
                    if value is NSNull { state.removeValue(forKey: key) } else { state[key] = value }
                }
            } else {
                state = payload
            }
            apply(state, artworkChanged: payload.keys.contains("artworkData"))
        }
    }

    private func apply(_ s: [String: Any], artworkChanged: Bool) {
        var n = NowPlaying()
        n.title = s["title"] as? String ?? ""
        n.artist = s["artist"] as? String ?? ""
        n.album = s["album"] as? String ?? ""
        n.bundleIdentifier = s["bundleIdentifier"] as? String
        n.isPlaying = s["playing"] as? Bool ?? false
        n.playbackRate = (s["playbackRate"] as? NSNumber)?.doubleValue ?? 0
        n.duration = ((s["durationMicros"] as? NSNumber)?.doubleValue ?? 0) / 1_000_000
        n.elapsed = ((s["elapsedTimeMicros"] as? NSNumber)?.doubleValue ?? 0) / 1_000_000
        if let ts = (s["timestampEpochMicros"] as? NSNumber)?.doubleValue {
            n.timestamp = Date(timeIntervalSince1970: ts / 1_000_000)
        }
        n.shuffleMode = (s["shuffleMode"] as? NSNumber)?.intValue
        n.repeatMode = (s["repeatMode"] as? NSNumber)?.intValue
        if artworkChanged || nowPlaying.title != n.title {
            if let b64 = s["artworkData"] as? String, let data = Data(base64Encoded: b64) {
                n.artwork = NSImage(data: data)
            }
        } else {
            n.artwork = nowPlaying.artwork
        }
        if n != nowPlaying { nowPlaying = n }
    }

    // MARK: - Komutlar

    func send(_ command: Command) {
        run(["send", String(command.rawValue)])
    }

    func seek(to seconds: TimeInterval) {
        run(["seek", String(Int(seconds * 1_000_000))])
        nowPlaying.elapsed = seconds
        nowPlaying.timestamp = .now
    }

    func openSourceApp() {
        guard let id = nowPlaying.bundleIdentifier,
              let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) else { return }
        NSWorkspace.shared.openApplication(at: url, configuration: .init())
    }

    private func run(_ args: [String]) {
        guard let script = scriptURL, let framework = frameworkURL else { return }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
        p.arguments = [script.path, framework.path] + args
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        try? p.run()
    }
}

extension MediaController {
    /// Bir şey çalıyorsa veya son birkaç saniyede duraklatıldıysa canlı aktivite gösterilir.
    var isActive: Bool { !nowPlaying.isEmpty && nowPlaying.isPlaying }
}
