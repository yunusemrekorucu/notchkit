import SwiftUI
import AVFoundation
import Defaults

/// Kamerayı ayna olarak gösterir; tıklayınca başlar/durur.
@MainActor
final class MirrorController: ObservableObject {
    enum State { case stopped, loading, mirroring, denied }
    @Published var state: State = .stopped
    let session = AVCaptureSession()

    func toggle() { state == .mirroring ? stop() : start() }

    func start() {
        state = .loading
        AVCaptureDevice.requestAccess(for: .video) { granted in
            Task { @MainActor in
                guard granted else { self.state = .denied; return }
                self.configure()
            }
        }
    }

    private func configure() {
        session.beginConfiguration()
        session.inputs.forEach { session.removeInput($0) }
        let device = Defaults[.mirrorDeviceID].flatMap(AVCaptureDevice.init(uniqueID:)) ?? AVCaptureDevice.default(for: .video)
        if let device, let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input) {
            session.addInput(input)
        }
        session.sessionPreset = .medium
        session.commitConfiguration()
        let session = self.session
        Task.detached { session.startRunning() }
        state = .mirroring
    }

    func stop() {
        let session = self.session
        Task.detached { session.stopRunning() }
        state = .stopped
    }
}

struct MirrorWidget: View {
    @StateObject private var controller = MirrorController()

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white.opacity(0.08))
                switch controller.state {
                case .mirroring:
                    CameraPreview(session: controller.session)
                case .loading:
                    ProgressView().controlSize(.small)
                case .denied:
                    Text("No camera access").font(.system(size: 10)).foregroundStyle(.white.opacity(0.6))
                case .stopped:
                    Image(systemName: "web.camera.fill").font(.system(size: 22)).foregroundStyle(.white.opacity(0.7))
                }
            }
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(Rectangle())
            .onTapGesture { controller.toggle() }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onDisappear { controller.stop() }
    }
}

private struct CameraPreview: NSViewRepresentable {
    let session: AVCaptureSession

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.setAffineTransform(CGAffineTransform(scaleX: -1, y: 1))
        view.layer = layer
        view.wantsLayer = true
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
