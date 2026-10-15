import AppKit
import Defaults

/// Nook genişliği sabit değil: etkin widget'ların hücre genişliklerinin toplamından hesaplanır.
/// Ekrana sığmayan widget'lar gizlenir.
enum NookLayout {
    static var unit: CGFloat { NotchGeometry.gridUnit }
    static var gap: CGFloat { CGFloat(Defaults[.widgetsPadding]) * 2 + 1 }

    static func width(of widget: NookWidget) -> CGFloat {
        CGFloat(widget.width) * unit
    }

    static func contentWidth(of widgets: [NookWidget]) -> CGFloat {
        guard !widgets.isEmpty else { return 0 }
        return widgets.reduce(0) { $0 + width(of: $1) } + CGFloat(widgets.count - 1) * gap
    }

    /// Sırayla eklenir; sığmayan ilk widget'tan sonrakiler gizlenir.
    static func visibleWidgets(maxContentWidth: CGFloat) -> [NookWidget] {
        var result: [NookWidget] = []
        for widget in Defaults[.nookWidgets] {
            let next = result + [widget]
            guard contentWidth(of: next) <= maxContentWidth else { break }
            result = next
        }
        return result
    }
}
