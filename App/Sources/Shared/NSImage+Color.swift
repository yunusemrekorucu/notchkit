import AppKit
import SwiftUI

extension NSImage {
    /// Görselin ortalama rengi (1x1 piksele küçültülerek), koyu renkler biraz aydınlatılır.
    var averageColor: NSColor? {
        guard let cg = cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        var pixel = [UInt8](repeating: 0, count: 4)
        guard let ctx = CGContext(data: &pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.interpolationQuality = .medium
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        let color = NSColor(red: CGFloat(pixel[0]) / 255, green: CGFloat(pixel[1]) / 255,
                            blue: CGFloat(pixel[2]) / 255, alpha: 1)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.usingColorSpace(.deviceRGB)?.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return NSColor(hue: h, saturation: min(1, s * 1.2), brightness: max(b, 0.7), alpha: 1)
    }
}

extension MediaController {
    var accentColor: Color {
        if let cached = AccentCache.shared.color(for: nowPlaying.artwork) { return cached }
        return .white
    }
}

private final class AccentCache {
    static let shared = AccentCache()
    private weak var image: NSImage?
    private var cached: Color?

    func color(for image: NSImage?) -> Color? {
        guard let image else { return nil }
        if image === self.image { return cached }
        self.image = image
        cached = image.averageColor.map(Color.init(nsColor:))
        return cached
    }
}
