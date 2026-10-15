import AppKit

/// Ekranın üst kenarına yapışık, tam genişlikte, şeffaf ve odak çalmayan panel.
/// Notch şekli bu sabit tuvalin içinde büyüyüp küçülür; pencere yeniden boyutlanmaz.
final class NotchPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        isMovable = false
        isReleasedWhenClosed = false
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        hidesOnDeactivate = false
        animationBehavior = .none
        ignoresMouseEvents = true
    }

    // Not yazma / dosya tepsisi gibi alanlarda klavye girdisi alabilmek için.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    /// Panel key olduğunda AppKit ilk metin alanını (Notlar, Yapılacaklar) kendiliğinden odaklar.
    /// Bu, "yazıyor" durumunu tetikleyip notch'un fare çıkınca kapanmasını engelliyordu.
    /// Odak yalnızca kullanıcı bir metin alanına tıkladığında verilsin.
    override func becomeKey() {
        super.becomeKey()
        if !(currentEvent?.type == .leftMouseDown && hitsTextInput(currentEvent!)) {
            makeFirstResponder(nil)
        }
    }

    /// Panel odağı kaybedince (başka yere tıklama, ⌘-Tab) çağrılır.
    var onResignKey: (() -> Void)?

    override func resignKey() {
        super.resignKey()
        onResignKey?()
    }

    /// Notch kapanınca odağı bırak; klavye girdisi gizli metin alanına gitmesin.
    func relinquishFocus() {
        makeFirstResponder(nil)
        guard isKeyWindow else { return }
        // Önde olan uygulamayı yeniden etkinleştirerek klavye odağını ona geri ver.
        NSWorkspace.shared.frontmostApplication?.activate()
    }

    private func hitsTextInput(_ event: NSEvent) -> Bool {
        guard let view = contentView?.hitTest(contentView!.convert(event.locationInWindow, from: nil)) else { return false }
        return view is NSTextView || view is NSTextField
    }
}
