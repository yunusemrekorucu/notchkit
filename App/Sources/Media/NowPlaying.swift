import AppKit

struct NowPlaying: Equatable {
    var title: String = ""
    var artist: String = ""
    var album: String = ""
    var bundleIdentifier: String?
    var isPlaying: Bool = false
    var playbackRate: Double = 0
    var duration: TimeInterval = 0
    var elapsed: TimeInterval = 0
    /// `elapsed` değerinin ölçüldüğü an.
    var timestamp: Date = .now
    var artwork: NSImage?
    var shuffleMode: Int?
    var repeatMode: Int?

    var isEmpty: Bool { title.isEmpty }

    /// Anlık geçen süre: elapsed + (şimdi - timestamp) * rate
    func elapsed(at date: Date) -> TimeInterval {
        guard isPlaying else { return elapsed }
        let value = elapsed + date.timeIntervalSince(timestamp) * max(playbackRate, 1)
        return duration > 0 ? min(value, duration) : value
    }

    var appIcon: NSImage? {
        guard let id = bundleIdentifier,
              let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) else { return nil }
        return NSWorkspace.shared.icon(forFile: url.path)
    }

    static func == (l: NowPlaying, r: NowPlaying) -> Bool {
        l.title == r.title && l.artist == r.artist && l.album == r.album && l.isPlaying == r.isPlaying
            && l.elapsed == r.elapsed && l.duration == r.duration && l.bundleIdentifier == r.bundleIdentifier
            && l.artwork === r.artwork && l.shuffleMode == r.shuffleMode && l.repeatMode == r.repeatMode
    }
}
