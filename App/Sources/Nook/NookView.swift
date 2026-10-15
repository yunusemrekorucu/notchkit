import SwiftUI
import Defaults

/// Nook sekmesi: etkin widget'lar kendi hücre genişlikleriyle yan yana, aralarında ince ayraçlar.
struct NookView: View {
    @EnvironmentObject private var model: NotchViewModel
    // Değişince yeniden çizim için gözlemleniyor.
    @Default(.nookWidgets) private var widgets
    @Default(.widgetWidths) private var widths
    @Default(.shortcutsToDisplay) private var shortcuts
    @Default(.shortcutColumnWidth) private var shortcutColumnWidth
    @Default(.quickApps) private var quickApps
    @Default(.nookShowDividers) private var showDividers
    @Default(.widgetsPadding) private var spacing

    var body: some View {
        let visible = model.visibleNookWidgets
        HStack(spacing: 0) {
            ForEach(Array(visible.enumerated()), id: \.element) { index, widget in
                if index > 0 {
                    Rectangle()
                        .fill(.white.opacity(showDividers ? 0.1 : 0))
                        .frame(width: 1)
                        .padding(.vertical, 6)
                        .padding(.horizontal, CGFloat(spacing))
                }
                widgetView(widget)
                    .frame(width: NookLayout.width(of: widget))
                    .frame(maxHeight: .infinity)
                    .clipped()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            if visible.isEmpty {
                Text("Ayarlardan widget ekleyin")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    @ViewBuilder
    private func widgetView(_ widget: NookWidget) -> some View {
        switch widget {
        case .media: MediaWidget()
        case .calendar: CalendarWidget()
        case .shortcuts: ShortcutsWidget()
        case .mirror: MirrorWidget()
        case .notes: NotesWidget()
        case .todo: TodoWidget()
        case .pomodoro: PomodoroWidget()
        case .quickApps: QuickAppsWidget()
        }
    }
}

/// Widget'lar için ortak yuvarlak/kare buton.
struct NookButton: View {
    var symbol: String
    var size: CGFloat = 30
    var fontSize: CGFloat = 14
    var action: () -> Void
    @State private var hovering = false
    @Default(.preferRoundButtons) private var round

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background {
                    if round { Circle().fill(.white.opacity(hovering ? 0.16 : 0)) }
                    else { RoundedRectangle(cornerRadius: 8).fill(.white.opacity(hovering ? 0.16 : 0)) }
                }
                .scaleEffect(hovering ? 1.06 : 1)
        }
        .buttonStyle(.plain)
        .onHover { h in withAnimation(.easeOut(duration: 0.12)) { hovering = h } }
    }
}
