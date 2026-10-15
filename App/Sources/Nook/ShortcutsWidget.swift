import SwiftUI
import Defaults

/// macOS Kestirmeler uygulamasındaki kestirmeleri `shortcuts` komut satırı aracıyla listeler ve çalıştırır.
enum ShortcutsService {
    static func list() async -> [String] {
        await Task.detached {
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
            p.arguments = ["list"]
            let pipe = Pipe()
            p.standardOutput = pipe
            p.standardError = FileHandle.nullDevice
            guard (try? p.run()) != nil else { return [] }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            p.waitUntilExit()
            return String(decoding: data, as: UTF8.self)
                .split(separator: "\n").map(String.init).filter { !$0.isEmpty }
        }.value
    }

    static func run(_ name: String) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        p.arguments = ["run", name]
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        try? p.run()
    }
}

struct ShortcutsWidget: View {
    @Default(.shortcutsToDisplay) private var shortcuts
    @Default(.shortcutColumnWidth) private var columnCells
    private let spacing: CGFloat = 8

    /// Kestirmeler 2 satırlı sütunlara bölünür; widget genişliği sütun sayısıyla büyür.
    private var columns: [[String]] {
        stride(from: 0, to: shortcuts.count, by: 2).map { Array(shortcuts[$0..<min($0 + 2, shortcuts.count)]) }
    }

    var body: some View {
        if shortcuts.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "sparkles").font(.system(size: 20)).foregroundStyle(.white.opacity(0.7))
                Button { SettingsOpener.open(tab: .widgets, widget: .shortcuts) } label: {
                    Text("Kestirme seç")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Capsule().fill(.white.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            let columnWidth = CGFloat(columnCells) * NookLayout.unit
            HStack(spacing: 0) {
                ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                    VStack(spacing: spacing) {
                        ForEach(column, id: \.self) { ShortcutButton(name: $0) }
                        if column.count == 1 { Color.clear }
                    }
                    .padding(.horizontal, spacing / 2)
                    .frame(width: columnWidth)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct ShortcutButton: View {
    let name: String
    @State private var hovering = false
    @Default(.preferRoundButtons) private var round

    var body: some View {
        Button { ShortcutsService.run(name) } label: {
            HStack(spacing: 6) {
                Image(systemName: "square.stack.3d.up.fill").font(.system(size: 11))
                Text(name).font(.system(size: 11, weight: .medium)).lineLimit(1)
                Spacer(minLength: 0)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(RoundedRectangle(cornerRadius: round ? 100 : 10, style: .continuous)
                .fill(.white.opacity(hovering ? 0.18 : 0.1)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help(name)
    }
}
