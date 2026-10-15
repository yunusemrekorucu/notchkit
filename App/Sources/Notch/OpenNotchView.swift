import SwiftUI
import Defaults

/// Açık notch: üstte sekme başlığı, altta Nook ya da Tray içeriği.
struct OpenNotchView: View {
    @EnvironmentObject private var model: NotchViewModel
    @Default(.contentPadding) private var padding

    var body: some View {
        VStack(spacing: 0) {
            NotchHeaderView()
                .frame(height: model.closedSize.height)
                .padding(.horizontal, CGFloat(padding) + 4)

            Group {
                switch model.tab {
                case .nook: NookView()
                case .tray: TrayView()
                }
            }
            .padding(.horizontal, CGFloat(padding))
            .padding(.bottom, CGFloat(padding))
            .padding(.top, CGFloat(padding) / 2)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity)
        }
    }
}

struct NotchHeaderView: View {
    @EnvironmentObject private var model: NotchViewModel
    @ObservedObject private var battery = BatteryMonitor.shared
    @ObservedObject private var tray = TrayStore.shared

    var body: some View {
        HStack(spacing: 6) {
            TabPill(title: "Nook", symbol: "lamp.desk.fill", selected: model.tab == .nook) {
                withAnimation(.notchOpen) { model.tab = .nook }
            }
            TabPill(title: "Tray", symbol: "tray.fill", selected: model.tab == .tray,
                    badge: tray.items.isEmpty ? nil : tray.items.count) {
                withAnimation(.notchOpen) { model.tab = .tray }
            }
            Spacer(minLength: model.closedSize.width)
            if battery.hasBattery {
                HStack(spacing: 4) {
                    Text("\(battery.level)%")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                    BatteryGlyph(level: battery.level, charging: battery.isPluggedIn)
                }
            }
            HeaderIconButton(symbol: "gearshape.fill") {
                model.close()
                SettingsOpener.open()
            }
        }
    }
}

struct TabPill: View {
    var title: String
    var symbol: String
    var selected: Bool
    var badge: Int? = nil
    var action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: symbol).font(.system(size: 11, weight: .semibold))
                Text(title).font(.system(size: 12, weight: .semibold))
                if let badge {
                    Text("\(badge)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .background(Capsule().fill(.white.opacity(0.2)))
                }
            }
            .foregroundStyle(selected ? .black : .white.opacity(hovering ? 1 : 0.7))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(selected ? Color.white : Color.white.opacity(hovering ? 0.12 : 0)))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

struct HeaderIconButton: View {
    var symbol: String
    var action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(hovering ? 1 : 0.7))
                .frame(width: 26, height: 26)
                .background(Circle().fill(.white.opacity(hovering ? 0.15 : 0.08)))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
