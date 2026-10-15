import SwiftUI
import QuickLookThumbnailing

struct TrayView: View {
    @EnvironmentObject private var model: NotchViewModel
    @ObservedObject private var tray = TrayStore.shared

    var body: some View {
        HStack(spacing: 10) {
            filesArea
            DropTarget(title: "AirDrop", symbol: "dot.radiowaves.left.and.right", tint: .blue) { urls in
                tray.airDrop(urls)
            }
            .frame(width: NotchGeometry.gridUnit * 2)
        }
    }

    @ViewBuilder
    private var filesArea: some View {
        if tray.items.isEmpty {
            DropTarget(title: "Drop files here", symbol: "tray.and.arrow.down.fill", tint: .white) { urls in
                tray.add(urls)
            }
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tray.items) { item in TrayItemView(item: item) }
                }
                .padding(.horizontal, 4)
                .frame(maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white.opacity(0.05)))
            .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                loadFileURLs(from: providers) { tray.add($0) }
                return true
            }
            .overlay(alignment: .topTrailing) {
                Button { tray.removeAll() } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.white.opacity(0.4))
                }
                .buttonStyle(.plain).padding(6).help("Clear Tray")
            }
        }
    }
}

struct DropTarget: View {
    var title: LocalizedStringKey
    var symbol: String
    var tint: Color
    var onDrop: ([URL]) -> Void
    @State private var targeted = false

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(targeted ? tint : .white.opacity(0.7))
                .scaleEffect(targeted ? 1.12 : 1)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                .foregroundStyle(.white.opacity(targeted ? 0.6 : 0.2))
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(tint.opacity(targeted ? 0.15 : 0.03)))
        )
        .animation(.easeOut(duration: 0.15), value: targeted)
        .onDrop(of: [.fileURL], isTargeted: $targeted) { providers in
            loadFileURLs(from: providers, completion: onDrop)
            return true
        }
    }
}

struct TrayItemView: View {
    let item: TrayItem
    @ObservedObject private var tray = TrayStore.shared
    @State private var thumbnail: NSImage?
    @State private var hovering = false

    var body: some View {
        VStack(spacing: 4) {
            Group {
                if let thumbnail { Image(nsImage: thumbnail).resizable().aspectRatio(contentMode: .fit) }
                else { Image(nsImage: NSWorkspace.shared.icon(forFile: item.url.path)).resizable() }
            }
            .frame(width: 48, height: 48)
            Text(item.name)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .truncationMode(.middle)
                .frame(width: 72)
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(hovering ? 0.12 : 0)))
        .onHover { hovering = $0 }
        .onTapGesture(count: 2) { tray.open(item) }
        .onDrag { NSItemProvider(contentsOf: item.url) ?? NSItemProvider() }
        .contextMenu {
            Button("Open") { tray.open(item) }
            Button("Show in Finder") { tray.reveal(item) }
            Button("Copy") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.writeObjects([item.url as NSURL])
            }
            Button("Send with AirDrop") { tray.airDrop([item.url]) }
            Divider()
            Button("Remove from Tray", role: .destructive) { tray.remove(item) }
        }
        .task(id: item.url) {
            let request = QLThumbnailGenerator.Request(fileAt: item.url, size: CGSize(width: 96, height: 96),
                                                       scale: 2, representationTypes: .thumbnail)
            if let rep = try? await QLThumbnailGenerator.shared.generateBestRepresentation(for: request) {
                thumbnail = rep.nsImage
            }
        }
    }
}
