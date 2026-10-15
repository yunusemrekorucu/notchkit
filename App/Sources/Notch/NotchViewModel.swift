import SwiftUI
import Combine
import Defaults

enum NotchStatus: Equatable { case closed, peeking, opened }
enum NotchTab: String, CaseIterable, Identifiable { case nook, tray; var id: String { rawValue } }

/// Bir ekrandaki notch'un tüm durumu: açık/kapalı, sekme, boyutlar, canlı aktivite.
@MainActor
final class NotchViewModel: ObservableObject {
    let screen: NSScreen
    let geometry: NotchGeometry

    @Published var status: NotchStatus = .closed
    @Published var tab: NotchTab = .nook
    @Published var isHovering = false
    @Published var isDraggingFiles = false
    /// Kullanıcı notch içinde yazı yazarken (Not widget'ı vb.) otomatik kapanmayı engeller.
    @Published var isTyping = false
    /// Geçici olarak gösterilen "hızlı bakış" etkinliği (ör. şarkı değişti).
    @Published var quickPeek: LiveActivityKind?

    private var cancellables = Set<AnyCancellable>()

    init(screen: NSScreen) {
        self.screen = screen
        self.geometry = NotchGeometry(screen: screen)

        Defaults.publisher(keys: .cellSize, .contentPadding, .nookHeight, .trayWidth, .trayHeight,
                           .notchWidthFineTune, .notchHeightFineTune, .nookWidgets, .widgetWidths,
                           .shortcutsToDisplay, .shortcutColumnWidth, .widgetsPadding, .quickApps)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        MediaController.shared.$nowPlaying
            .map(\.title).removeDuplicates().dropFirst()
            .sink { [weak self] title in
                guard let self, !title.isEmpty, Defaults[.enableQuickPeek] else { return }
                self.showQuickPeek(.media)
            }
            .store(in: &cancellables)
    }

    // MARK: - Boyutlar

    var closedSize: CGSize {
        geometry.closedSize(widthFineTune: Defaults[.notchWidthFineTune],
                            heightFineTune: Defaults[.notchHeightFineTune])
    }

    /// Üst başlığın (sekmeler + notch + pil/ayarlar) sığması için gereken en küçük genişlik.
    var minimumOpenWidth: CGFloat { closedSize.width + 320 }

    /// Ekrandan taşmaması için Nook içeriğinin alabileceği en büyük genişlik.
    var maximumContentWidth: CGFloat {
        screen.frame.width - 80 - CGFloat(Defaults[.contentPadding]) * 2
    }

    var visibleNookWidgets: [NookWidget] {
        NookLayout.visibleWidgets(maxContentWidth: maximumContentWidth)
    }

    var openSize: CGSize {
        let unit = NotchGeometry.gridUnit
        let padding = CGFloat(Defaults[.contentPadding])
        let header = closedSize.height
        let contentWidth: CGFloat, rows: Int
        switch tab {
        case .nook:
            contentWidth = NookLayout.contentWidth(of: visibleNookWidgets)
            rows = Defaults[.nookHeight]
        case .tray:
            contentWidth = CGFloat(Defaults[.trayWidth]) * unit
            rows = Defaults[.trayHeight]
        }
        return CGSize(width: max(contentWidth + padding * 2, minimumOpenWidth),
                      height: header + CGFloat(rows) * unit + padding * 1.5)
    }

    /// Kapalıyken canlı aktivite varsa notch yanlara genişler.
    var activeLiveActivity: LiveActivityKind? {
        LiveActivityKind.current(quickPeek: quickPeek)
    }

    var closedDisplaySize: CGSize {
        var s = closedSize
        if let activity = activeLiveActivity {
            s.width += activity.extraWidth * 2
            if activity == quickPeek, activity.peekHeight > 0 { s.height += activity.peekHeight }
        }
        return s
    }

    var currentSize: CGSize {
        switch status {
        case .opened: openSize
        case .peeking: CGSize(width: closedDisplaySize.width + 16, height: closedDisplaySize.height + 6)
        case .closed: closedDisplaySize
        }
    }

    var cornerRadii: (top: CGFloat, bottom: CGFloat) {
        status == .opened ? (10, 24) : (4, 12)
    }

    /// Notch'un ekran koordinatlarındaki dikdörtgeni (AppKit, sol-alt köken).
    func notchRect(in size: CGSize? = nil) -> NSRect {
        let s = size ?? currentSize
        let frame = screen.frame
        return NSRect(x: frame.midX - s.width / 2, y: frame.maxY - s.height + 1, width: s.width, height: s.height)
    }

    // MARK: - Eylemler

    func open(tab: NotchTab? = nil) {
        if let tab { self.tab = tab }
        guard status != .opened else { return }
        Haptics.tap()
        withAnimation(.notchOpen) { status = .opened }
    }

    func close() {
        guard status != .closed else { return }
        withAnimation(.notchClose) { status = .closed }
        isTyping = false
    }

    func peek() {
        guard status == .closed else { return }
        Haptics.tap()
        withAnimation(.notchOpen) { status = .peeking }
    }

    func showQuickPeek(_ kind: LiveActivityKind) {
        guard status == .closed else { return }
        withAnimation(.notchOpen) { quickPeek = kind }
        let current = kind
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            guard let self, self.quickPeek == current else { return }
            withAnimation(.notchClose) { self.quickPeek = nil }
        }
    }
}

extension Animation {
    static let notchOpen = Animation.spring(response: 0.42, dampingFraction: 0.8)
    static let notchClose = Animation.spring(response: 0.38, dampingFraction: 1.0)
}

enum Haptics {
    static func tap() {
        guard !Defaults[.disableHaptics] else { return }
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
    }
}
