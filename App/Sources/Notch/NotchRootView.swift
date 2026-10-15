import SwiftUI
import Defaults

/// Tam genişlikteki şeffaf tuvalin içinde, üst ortaya hizalanmış notch.
struct NotchRootView: View {
    @EnvironmentObject private var model: NotchViewModel
    @ObservedObject private var media = MediaController.shared
    @ObservedObject private var battery = BatteryMonitor.shared
    @ObservedObject private var tray = TrayStore.shared
    @ObservedObject private var pomodoro = PomodoroStore.shared
    @Default(.translucent) private var translucent

    var body: some View {
        let size = model.currentSize
        let radii = model.cornerRadii
        let shape = NotchShape(topRadius: radii.top, bottomRadius: radii.bottom)

        ZStack(alignment: .top) {
            // Şekil doğrudan doldurulur; böylece üst "kulaklar" çerçevenin dışına taşabilir.
            Group {
                if translucent {
                    VisualEffectView(material: .hudWindow)
                        .overlay(Color.black.opacity(0.35))
                        .mask(shape)
                } else {
                    shape.fill(Color.black)
                }
            }
            .shadow(color: .black.opacity(model.status == .opened ? 0.45 : 0), radius: 16, y: 6)

            // İçerik notch şekliyle maskelenir: küçülme animasyonu sırasında hiçbir şey şeklin dışına taşmaz.
            content
                .frame(width: size.width, height: size.height, alignment: .top)
                .mask(shape)
        }
        .frame(width: size.width, height: size.height)
        .contentShape(shape)
        .contextMenu {
            Button("Ayarları Aç") { SettingsOpener.open() }
            Divider()
            Button("Nook'tan Çık") { NSApp.terminate(nil) }
        }
        .onDrop(of: [.fileURL], isTargeted: $model.isDraggingFiles) { providers in
            loadFileURLs(from: providers) { urls in
                tray.add(urls)
            }
            return true
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .environment(\.colorScheme, .dark)
        .animation(.notchOpen, value: media.isActive)
        .animation(.notchOpen, value: battery.showChargingActivity)
        .animation(.notchOpen, value: tray.items.count)
        .animation(.notchOpen, value: pomodoro.isRunning)
        .animation(.notchOpen, value: pomodoro.justFinished)
    }

    @ViewBuilder
    private var content: some View {
        switch model.status {
        case .opened:
            // Açık içerik kendi tam boyutunda sabit kalır; notch küçülürken yeniden yerleşmez.
            OpenNotchView()
                .frame(width: model.openSize.width, height: model.openSize.height, alignment: .top)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.97, anchor: .top))
                        .animation(.easeOut(duration: 0.22).delay(0.06)),
                    removal: .opacity.combined(with: .scale(scale: 0.96, anchor: .top))
                        .animation(.easeIn(duration: 0.06))))
        case .closed, .peeking:
            ClosedNotchView()
                .transition(.opacity.animation(.easeInOut(duration: 0.12)))
        }
    }
}

func loadFileURLs(from providers: [NSItemProvider], completion: @escaping @MainActor ([URL]) -> Void) {
    let group = DispatchGroup()
    var urls: [URL] = []
    let lock = NSLock()
    for provider in providers where provider.canLoadObject(ofClass: URL.self) {
        group.enter()
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            if let url, url.isFileURL { lock.lock(); urls.append(url); lock.unlock() }
            group.leave()
        }
    }
    group.notify(queue: .main) { MainActor.assumeIsolated { completion(urls) } }
}

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = .behindWindow
        v.state = .active
        return v
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) { nsView.material = material }
}
