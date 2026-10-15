import AppKit
import Defaults

/// Donanım notch'unun ve kapalı/açık notch boyutlarının hesaplanması.
struct NotchGeometry {
    /// Tuval yüksekliği: açık notch bunun içine sığar.
    static let canvasHeight: CGFloat = 400
    /// Bir ızgara hücresinin nokta karşılığı (Nook 11x2, Tray 12x2 hücre).
    static var gridUnit: CGFloat { CGFloat(Defaults[.cellSize]) }

    let screen: NSScreen

    var hasNotch: Bool { screen.safeAreaInsets.top > 0 }

    /// Donanım notch boyutu (notch'suz ekranlarda menü çubuğu yüksekliğinde sahte bir notch).
    var hardwareNotchSize: CGSize {
        guard hasNotch,
              let left = screen.auxiliaryTopLeftArea,
              let right = screen.auxiliaryTopRightArea else {
            let menuBar = screen.frame.maxY - screen.visibleFrame.maxY
            return CGSize(width: 200, height: max(menuBar, 24))
        }
        return CGSize(width: right.minX - left.maxX, height: screen.safeAreaInsets.top)
    }

    /// Kapalı notch: genişlik notch - 2, yükseklik notch + 1 (1 pt ekran dışında kalır).
    func closedSize(widthFineTune: CGFloat = 0, heightFineTune: CGFloat = 0) -> CGSize {
        let hw = hardwareNotchSize
        return CGSize(width: hw.width - 2 + widthFineTune, height: hw.height + 1 + heightFineTune)
    }

    /// Panelin çerçevesi (AppKit koordinatları): ekranın üstünden 1 pt yukarı taşar.
    var panelFrame: NSRect {
        NSRect(x: screen.frame.minX,
               y: screen.frame.maxY - Self.canvasHeight + 1,
               width: screen.frame.width,
               height: Self.canvasHeight)
    }
}

extension NSScreen {
    var displayID: CGDirectDisplayID {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
    }

    static var notchedScreen: NSScreen? {
        screens.first { $0.safeAreaInsets.top > 0 }
    }
}
