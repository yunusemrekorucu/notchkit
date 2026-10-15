import SwiftUI

@main
struct NookApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowManager: NotchWindowManager?
    private var termSource: DispatchSourceSignal?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        windowManager = NotchWindowManager()
        MediaController.shared.start()
        BatteryMonitor.shared.start()
        TrayStore.shared.load()

        // `kill`/`pkill` ile kapatıldığında da perl yardımcı süreci sonlandırılsın.
        signal(SIGTERM, SIG_IGN)
        let source = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        source.setEventHandler { NSApp.terminate(nil) }
        source.resume()
        termSource = source
    }

    func applicationWillTerminate(_ notification: Notification) {
        MediaController.shared.stop()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        SettingsOpener.open()
        return true
    }
}

/// LSUIElement uygulamalarda SwiftUI `Settings` sahnesi güvenilir açılmadığı için kendi penceremiz.
enum SettingsOpener {
    @MainActor private static var window: NSWindow?

    @MainActor static func open(tab: SettingsTab? = nil, widget: NookWidget? = nil) {
        if let tab { SettingsNavigation.shared.tab = tab }
        if let widget { SettingsNavigation.shared.selectedWidget = widget }
        if window == nil {
            let w = NSWindow(contentViewController: NSHostingController(rootView: SettingsView()))
            w.title = "Nook Ayarları"
            w.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
            w.setContentSize(NSSize(width: 680, height: 620))
            w.isReleasedWhenClosed = false
            w.center()
            window = w
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
