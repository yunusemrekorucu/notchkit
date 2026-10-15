import SwiftUI
import AVFoundation
import Defaults
import UniformTypeIdentifiers

struct WidgetsSettings: View {
    @ObservedObject private var nav = SettingsNavigation.shared
    @Default(.nookWidgets) private var widgets
    @Default(.widgetWidths) private var widths
    @Default(.shortcutsToDisplay) private var shortcuts
    @Default(.shortcutColumnWidth) private var columnWidth
    @Default(.quickApps) private var quickApps
    @Default(.cellSize) private var cellSize
    @Default(.widgetsPadding) private var spacing
    @State private var dragging: NookWidget?

    private var maxContentWidth: CGFloat {
        let screen = NSScreen.notchedScreen ?? NSScreen.main
        return (screen?.frame.width ?? 1440) - 80 - CGFloat(Defaults[.contentPadding]) * 2
    }
    private var visible: [NookWidget] { NookLayout.visibleWidgets(maxContentWidth: maxContentWidth) }
    private var available: [NookWidget] { NookWidget.allCases.filter { !widgets.contains($0) } }

    var body: some View {
        Form {
            Section {
                NookPreview(widgets: visible)
                    .padding(.vertical, 4)
            } header: {
                Text("Preview")
            } footer: {
                let cells = visible.reduce(0) { $0 + $1.width }
                Text("\(cells) cells · \(Int(NookLayout.contentWidth(of: visible))) pt wide. The Nook's width adjusts to your widgets.")
            }

            Section {
                if widgets.isEmpty {
                    Text("No widgets yet. Add some below.").foregroundStyle(.secondary)
                }
                ForEach(widgets) { widget in
                    EnabledWidgetRow(
                        widget: widget,
                        isSelected: nav.selectedWidget == widget,
                        isHidden: !visible.contains(widget),
                        onSelect: { nav.selectedWidget = widget },
                        onRemove: { remove(widget) })
                    .opacity(dragging == widget ? 0.4 : 1)
                    .onDrag {
                        dragging = widget
                        return NSItemProvider(object: widget.rawValue as NSString)
                    }
                    .onDrop(of: [.text], delegate: ReorderDelegate(target: widget, widgets: $widgets, dragging: $dragging))
                }
            } header: {
                Text("Active widgets")
            } footer: {
                Text("Drag rows to reorder them. Settings for the selected widget appear below.")
            }

            Section("Add Widgets") {
                if available.isEmpty {
                    Text("All widgets are added.").foregroundStyle(.secondary)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 10)], spacing: 10) {
                        ForEach(available) { widget in
                            AddWidgetTile(widget: widget) {
                                withAnimation(.snappy) { widgets.append(widget) }
                                nav.selectedWidget = widget
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                widgetSettings(nav.selectedWidget)
            } header: {
                Label("\(nav.selectedWidget.title) settings", systemImage: nav.selectedWidget.symbol)
            }
        }
        .formStyle(.grouped)
        .animation(.snappy, value: widgets)
        .animation(.snappy, value: widths)
        .animation(.snappy, value: shortcuts)
        .animation(.snappy, value: quickApps)
    }

    private func remove(_ widget: NookWidget) {
        withAnimation(.snappy) { widgets.removeAll { $0 == widget } }
    }

    // MARK: - Seçili widget ayarları

    @ViewBuilder
    private func widgetSettings(_ widget: NookWidget) -> some View {
        if widget.isAutoWidth {
            LabeledContent("Width") {
                Text("Automatic · \(widget.width) cells").foregroundStyle(.secondary)
            }
        } else {
            ValueStepper("Width", value: Binding(get: { widget.width }, set: { widget.setWidth($0) }), in: 1...10, display: "\(widget.width) cells")
        }

        switch widget {
        case .calendar: CalendarWidgetSettings()
        case .shortcuts: ShortcutsWidgetSettings()
        case .mirror: MirrorWidgetSettings()
        case .todo: Defaults.Toggle(key: .showCompletedTodos) { Text("Show completed tasks") }
        case .pomodoro: PomodoroWidgetSettings()
        case .quickApps: QuickAppsWidgetSettings()
        case .media, .notes: EmptyView()
        }
    }
}

// MARK: - Önizleme

/// Açık notch'un küçültülmüş canlı önizlemesi.
private struct NookPreview: View {
    let widgets: [NookWidget]

    var body: some View {
        GeometryReader { proxy in
            let content = max(NookLayout.contentWidth(of: widgets), 1)
            let scale = min(1, (proxy.size.width - 24) / content)
            HStack(spacing: NookLayout.gap * scale) {
                ForEach(widgets) { widget in
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(widget.tint.gradient.opacity(0.85))
                        .overlay {
                            VStack(spacing: 3) {
                                Image(systemName: widget.symbol).font(.system(size: 13, weight: .semibold))
                                if NookLayout.width(of: widget) * scale > 56 {
                                    Text(widget.title).font(.system(size: 9, weight: .semibold)).lineLimit(1)
                                }
                                Text("\(widget.width)").font(.system(size: 9, weight: .bold, design: .rounded)).opacity(0.7)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                        }
                        .frame(width: NookLayout.width(of: widget) * scale)
                }
            }
            .frame(height: 64)
            .padding(12)
            .background(UnevenRoundedRectangle(bottomLeadingRadius: 18, bottomTrailingRadius: 18).fill(.black))
            .frame(maxWidth: .infinity)
            .overlay {
                if widgets.isEmpty {
                    Text("Empty").font(.caption).foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .frame(height: 88)
    }
}

// MARK: - Satırlar ve kartlar

private struct EnabledWidgetRow: View {
    let widget: NookWidget
    let isSelected: Bool
    let isHidden: Bool
    let onSelect: () -> Void
    let onRemove: () -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.tertiary)
            WidgetIcon(widget: widget, size: 26)
            VStack(alignment: .leading, spacing: 1) {
                Text(widget.title).fontWeight(.medium)
                if isHidden {
                    Text("Hidden, doesn't fit on screen").font(.caption).foregroundStyle(.orange)
                }
            }
            Spacer()
            Text(widget.isAutoWidth ? String(localized: "Automatic · \(widget.width) cells") : String(localized: "\(widget.width) cells"))
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
            Button(action: onRemove) {
                Image(systemName: "minus.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .red)
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
            .help("Remove")
            .opacity(hovering || isSelected ? 1 : 0.5)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(RoundedRectangle(cornerRadius: 8).fill(isSelected ? Color.accentColor.opacity(0.18) : .clear))
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { hovering = $0 }
    }
}

private struct AddWidgetTile: View {
    let widget: NookWidget
    let onAdd: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: onAdd) {
            HStack(spacing: 8) {
                WidgetIcon(widget: widget, size: 24)
                Text(widget.title).font(.callout.weight(.medium)).lineLimit(1)
                Spacer(minLength: 0)
                Image(systemName: "plus.circle.fill").foregroundStyle(.green)
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(hovering ? 0.1 : 0.05)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

struct WidgetIcon: View {
    let widget: NookWidget
    var size: CGFloat

    var body: some View {
        Image(systemName: widget.symbol)
            .font(.system(size: size * 0.5, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(RoundedRectangle(cornerRadius: size * 0.27, style: .continuous).fill(widget.tint.gradient))
    }
}

private struct ReorderDelegate: DropDelegate {
    let target: NookWidget
    @Binding var widgets: [NookWidget]
    @Binding var dragging: NookWidget?

    func dropEntered(info: DropInfo) {
        guard let dragging, dragging != target,
              let from = widgets.firstIndex(of: dragging),
              let to = widgets.firstIndex(of: target) else { return }
        withAnimation(.snappy) {
            widgets.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: .move) }

    func performDrop(info: DropInfo) -> Bool {
        dragging = nil
        return true
    }
}

// MARK: - Widget'a özel ayarlar

private struct PomodoroWidgetSettings: View {
    @Default(.pomodoroFocus) private var focus
    @Default(.pomodoroShortBreak) private var shortBreak
    @Default(.pomodoroLongBreak) private var longBreak
    @Default(.pomodoroSessionsBeforeLongBreak) private var sessions

    var body: some View {
        ValueStepper("Focus duration", value: $focus, in: 5...90, step: 5, display: "\(focus) min")
        ValueStepper("Short break", value: $shortBreak, in: 1...30, display: "\(shortBreak) min")
        ValueStepper("Long break", value: $longBreak, in: 5...60, step: 5, display: "\(longBreak) min")
        ValueStepper("Sessions before a long break", value: $sessions, in: 2...8, display: "\(sessions)")
        Defaults.Toggle(key: .pomodoroAutoStart) { Text("Start the next phase automatically") }
        Defaults.Toggle(key: .pomodoroPlaySound) { Text("Play a sound when a phase ends") }
            .onChange(of: focus) { PomodoroStore.shared.durationsChanged() }
            .onChange(of: shortBreak) { PomodoroStore.shared.durationsChanged() }
            .onChange(of: longBreak) { PomodoroStore.shared.durationsChanged() }
    }
}

private struct QuickAppsWidgetSettings: View {
    @Default(.quickApps) private var apps
    @State private var dragging: String?

    private var runningApps: [NSRunningApplication] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.bundleURL != nil && !apps.contains($0.bundleURL!.path) }
            .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
    }

    var body: some View {
        Text("Each column holds 2 apps, and the widget grows with the number of apps. You can also drag apps from Finder or the Dock onto the widget.")
            .font(.caption).foregroundStyle(.secondary)

        ForEach(apps, id: \.self) { path in
            let url = URL(fileURLWithPath: path)
            HStack(spacing: 10) {
                Image(systemName: "line.3.horizontal").foregroundStyle(.tertiary)
                Image(nsImage: NSWorkspace.shared.icon(forFile: path)).resizable().frame(width: 24, height: 24)
                Text(QuickAppsStore.displayName(url))
                Spacer()
                Button { QuickAppsStore.shared.remove(path) } label: {
                    Image(systemName: "minus.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .red)
                }
                .buttonStyle(.plain)
            }
            .opacity(dragging == path ? 0.4 : 1)
            .onDrag {
                dragging = path
                return NSItemProvider(object: path as NSString)
            }
            .onDrop(of: [.text], delegate: ListReorderDelegate(target: path, items: $apps, dragging: $dragging))
        }

        HStack {
            Button("Add App…") { QuickAppsStore.shared.pickApps() }
            Menu("Add Running App") {
                ForEach(runningApps, id: \.processIdentifier) { app in
                    Button(app.localizedName ?? String(localized: "App")) {
                        if let url = app.bundleURL { QuickAppsStore.shared.add([url]) }
                    }
                }
            }
            .fixedSize()
        }
    }
}

/// Basit bir liste için sürükle-sırala.
private struct ListReorderDelegate<Item: Equatable>: DropDelegate {
    let target: Item
    @Binding var items: [Item]
    @Binding var dragging: Item?

    func dropEntered(info: DropInfo) {
        guard let dragging, dragging != target,
              let from = items.firstIndex(of: dragging),
              let to = items.firstIndex(of: target) else { return }
        withAnimation(.snappy) {
            items.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: .move) }

    func performDrop(info: DropInfo) -> Bool {
        dragging = nil
        return true
    }
}

private struct CalendarWidgetSettings: View {
    @Default(.calendarDaysAhead) private var daysAhead

    var body: some View {
        ValueStepper("Days to show", value: $daysAhead, in: 1...30, display: "\(daysAhead)")
        Defaults.Toggle(key: .calendarShowAllDay) { Text("Show all-day events") }
    }
}

private struct ShortcutsWidgetSettings: View {
    @Default(.shortcutsToDisplay) private var shortcuts
    @Default(.shortcutColumnWidth) private var columnWidth
    @State private var available: [String]?

    var body: some View {
        ValueStepper("Column width", value: $columnWidth, in: 1...4, display: "\(columnWidth) cells")
        Text("Each column holds 2 shortcuts, and the widget grows with the number of shortcuts you pick.")
            .font(.caption).foregroundStyle(.secondary)

        if let available {
            if available.isEmpty {
                Text("No shortcuts found in the Shortcuts app.").foregroundStyle(.secondary)
            }
            ForEach(available, id: \.self) { name in
                Toggle(isOn: Binding(
                    get: { shortcuts.contains(name) },
                    set: { on in if on { shortcuts.append(name) } else { shortcuts.removeAll { $0 == name } } })) {
                    Label(name, systemImage: "square.stack.3d.up.fill")
                }
            }
        } else {
            HStack { ProgressView().controlSize(.small); Text("Loading shortcuts…").foregroundStyle(.secondary) }
                .task { available = await ShortcutsService.list() }
        }
    }
}

private struct MirrorWidgetSettings: View {
    @Default(.mirrorDeviceID) private var deviceID
    private let devices = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInWideAngleCamera, .external, .continuityCamera],
        mediaType: .video, position: .unspecified).devices

    var body: some View {
        Picker("Camera", selection: $deviceID) {
            Text("Default").tag(String?.none)
            ForEach(devices, id: \.uniqueID) { Text($0.localizedName).tag(Optional($0.uniqueID)) }
        }
    }
}

/// Etiket solda, değer ve +/- sağda hizalı stepper satırı.
struct ValueStepper: View {
    let title: LocalizedStringKey
    @Binding var value: Int
    let range: ClosedRange<Int>
    var step: Int = 1
    let display: LocalizedStringKey

    init(_ title: LocalizedStringKey, value: Binding<Int>, in range: ClosedRange<Int>, step: Int = 1, display: LocalizedStringKey) {
        self.title = title
        self._value = value
        self.range = range
        self.step = step
        self.display = display
    }

    var body: some View {
        LabeledContent(title) {
            HStack(spacing: 8) {
                Text(display).foregroundStyle(.secondary).monospacedDigit()
                Stepper("", value: $value, in: range, step: step).labelsHidden()
            }
        }
    }
}
