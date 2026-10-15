import AppKit
import SwiftUI
import Defaults
import Combine

/// Her ekran için bir notch paneli oluşturur; fare ve sürükle-bırak olaylarını izler.
@MainActor
final class NotchWindowManager {
    private struct Entry {
        let panel: NotchPanel
        let model: NotchViewModel
    }

    private var entries: [CGDirectDisplayID: Entry] = [:]
    private var monitors: [Any] = []
    private var dragChangeCount = NSPasteboard(name: .drag).changeCount
    private var closeWork: [CGDirectDisplayID: DispatchWorkItem] = [:]
    private var cancellables = Set<AnyCancellable>()
    private var horizontalSwipe: CGFloat = 0

    init() {
        rebuild()
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in self?.rebuild() }
            .store(in: &cancellables)
        Defaults.publisher(.enableOnNonNotchScreens, options: [])
            .sink { [weak self] _ in Task { @MainActor in self?.rebuild() } }
            .store(in: &cancellables)
        installMonitors()
    }

    private func rebuild() {
        let screens = NSScreen.screens.filter { $0.safeAreaInsets.top > 0 || Defaults[.enableOnNonNotchScreens] }
        let ids = Set(screens.map(\.displayID))
        for (id, entry) in entries where !ids.contains(id) {
            entry.panel.orderOut(nil)
            entries[id] = nil
        }
        for screen in screens {
            let geometry = NotchGeometry(screen: screen)
            if let existing = entries[screen.displayID], existing.model.screen.frame == screen.frame {
                existing.panel.setFrame(geometry.panelFrame, display: true)
                continue
            }
            entries[screen.displayID]?.panel.orderOut(nil)
            let model = NotchViewModel(screen: screen)
            let panel = NotchPanel(contentRect: geometry.panelFrame)
            let host = NSHostingView(rootView: NotchRootView().environmentObject(model))
            host.frame = NSRect(origin: .zero, size: geometry.panelFrame.size)
            host.autoresizingMask = [.width, .height]
            panel.contentView = host
            panel.setFrame(geometry.panelFrame, display: true)
            panel.orderFrontRegardless()
            // Yazma kilidi yalnızca panel odaktayken geçerli; odak gidince kilit kalkar ve gerekirse kapanır.
            panel.onResignKey = { [weak model] in
                guard let model else { return }
                model.isTyping = false
                if model.status == .opened, !model.isHovering, !model.isDraggingFiles { model.close() }
            }
            model.$status
                .removeDuplicates()
                .filter { $0 == .closed }
                .sink { [weak panel] _ in panel?.relinquishFocus() }
                .store(in: &cancellables)
            entries[screen.displayID] = Entry(panel: panel, model: model)
        }
    }

    // MARK: - Olay izleme

    private func installMonitors() {
        let mask: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged, .leftMouseDown, .leftMouseUp, .scrollWheel]
        if let global = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: { [weak self] event in
            Task { @MainActor in self?.handle(event, local: false) }
        }) { monitors.append(global) }
        if let local = NSEvent.addLocalMonitorForEvents(matching: mask, handler: { [weak self] event in
            self?.handle(event, local: true)
            return event
        }) { monitors.append(local) }
    }

    private func handle(_ event: NSEvent, local: Bool) {
        let mouse = NSEvent.mouseLocation
        for (id, entry) in entries {
            process(event, mouse: mouse, id: id, entry: entry, local: local)
        }
    }

    private func process(_ event: NSEvent, mouse: NSPoint, id: CGDirectDisplayID, entry: Entry, local: Bool) {
        let model = entry.model
        let rect = model.notchRect()
        let hoverRect = rect.insetBy(dx: -4, dy: -4)
        let inside = hoverRect.contains(mouse)

        // Şeffaf alanlarda tıklamalar alttaki uygulamalara geçsin.
        entry.panel.ignoresMouseEvents = !inside
        if inside, model.status == .opened, !entry.panel.isKeyWindow, event.type == .leftMouseDown {
            entry.panel.makeKey()
        }

        switch event.type {
        case .leftMouseDragged:
            handleDrag(mouse: mouse, model: model, rect: rect)
        case .leftMouseUp:
            if model.isDraggingFiles {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { model.isDraggingFiles = false }
            }
        case .leftMouseDown:
            if inside, model.status != .opened { model.open() }
            // Notch dışına tıklama açık notch'u kapatır (yazarken de).
            if !inside, model.status == .opened { model.close() }
        case .scrollWheel:
            // Pozitif = parmaklar aşağı doğru kaydırıyor (doğal kaydırma ayarından bağımsız).
            let fingerDown = event.isDirectionInvertedFromDevice ? event.scrollingDeltaY : -event.scrollingDeltaY
            if inside, fingerDown > 3, model.status != .opened { model.open() }
            if inside, fingerDown < -6, model.status == .opened { model.close() }
            handleHorizontalSwipe(event, inside: inside)
        default:
            break
        }

        updateHover(inside: inside, model: model, id: id)
    }

    private func updateHover(inside: Bool, model: NotchViewModel, id: CGDirectDisplayID) {
        if inside {
            closeWork[id]?.cancel()
            closeWork[id] = nil
            if !model.isHovering { model.isHovering = true }
            if model.status == .closed {
                Defaults[.alwaysOpenNotchOnHover] ? model.open() : model.peek()
            }
            return
        }
        guard model.isHovering || model.status != .closed else { return }
        model.isHovering = false
        if model.status == .peeking { model.close(); return }
        guard model.status == .opened, closeWork[id] == nil, !model.isDraggingFiles else { return }
        if model.isTyping && Defaults[.preventUnhoverCloseWhenTyping] { return }
        let work = DispatchWorkItem { [weak self] in
            self?.closeWork[id] = nil
            guard !model.isHovering, !model.isDraggingFiles else { return }
            model.close()
        }
        closeWork[id] = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)
    }

    /// Notch üzerinde yatay iki parmak kaydırma: sonraki / önceki parça.
    private func handleHorizontalSwipe(_ event: NSEvent, inside: Bool) {
        guard inside, Defaults[.horizontalSwipeChangesTrack], event.hasPreciseScrollingDeltas else { return }
        if event.phase == .began { horizontalSwipe = 0 }
        if abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) { horizontalSwipe += event.scrollingDeltaX }
        guard event.phase == .ended || event.phase == .cancelled else { return }
        defer { horizontalSwipe = 0 }
        guard abs(horizontalSwipe) > 60, !MediaController.shared.nowPlaying.isEmpty else { return }
        let fingersLeft = event.isDirectionInvertedFromDevice ? horizontalSwipe < 0 : horizontalSwipe > 0
        Haptics.tap()
        MediaController.shared.send(fingersLeft ? .nextTrack : .previousTrack)
    }

    /// Dosya sürüklenirken notch'a yaklaşılırsa Tray sekmesiyle açılır.
    private func handleDrag(mouse: NSPoint, model: NotchViewModel, rect: NSRect) {
        let pasteboard = NSPasteboard(name: .drag)
        guard pasteboard.changeCount != dragChangeCount || model.isDraggingFiles else { return }
        let hasFiles = pasteboard.canReadObject(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true])
        guard hasFiles else { return }
        let activation = rect.insetBy(dx: -60, dy: -40)
        if activation.contains(mouse) {
            dragChangeCount = pasteboard.changeCount
            model.isDraggingFiles = true
            // Nook açıkken sekme değiştirme: dosya bir widget'a (ör. Hızlı Uygulamalar) bırakılıyor olabilir.
            if model.status != .opened { model.open(tab: .tray) }
        }
    }
}
