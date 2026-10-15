import SwiftUI

/// Üstte menü çubuğuna doğru açılan içbükey "kulaklar", altta dışbükey yuvarlatılmış köşeler.
struct NotchShape: Shape {
    var topRadius: CGFloat
    var bottomRadius: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { .init(topRadius, bottomRadius) }
        set { topRadius = newValue.first; bottomRadius = newValue.second }
    }

    func path(in rect: CGRect) -> Path {
        let t = topRadius
        let b = min(bottomRadius, (rect.height - t) / 2, rect.width / 2)
        var p = Path()
        // Sol üst kulak
        p.move(to: CGPoint(x: rect.minX - t, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY + t),
                       control: CGPoint(x: rect.minX, y: rect.minY))
        // Sol kenar ve sol alt köşe
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - b))
        p.addQuadCurve(to: CGPoint(x: rect.minX + b, y: rect.maxY),
                       control: CGPoint(x: rect.minX, y: rect.maxY))
        // Alt kenar ve sağ alt köşe
        p.addLine(to: CGPoint(x: rect.maxX - b, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY - b),
                       control: CGPoint(x: rect.maxX, y: rect.maxY))
        // Sağ kenar ve sağ üst kulak
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + t))
        p.addQuadCurve(to: CGPoint(x: rect.maxX + t, y: rect.minY),
                       control: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}
