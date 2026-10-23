//
//  ProductivityWidgetViews.swift
//  NotchKit
//
//  Pomodoro, To-dos and Quick Apps widgets: a large rounded readout with a gradient ring
//  on the left, compact stat rows on the right, and the shared mini-list chrome for lists.

import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Pomodoro

struct PomodoroWidgetView: View {
    @ObservedObject private var pomodoro = PomodoroManager.shared

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            HStack(spacing: 8) {
                Button(action: pomodoro.toggle) {
                    PomodoroRing(pomodoro: pomodoro)
                }
                .buttonStyle(.plain)
                .help(pomodoro.isRunning ? "Pause" : "Start")

                VStack(alignment: .leading, spacing: 2) {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Text(PomodoroManager.format(pomodoro.remaining(at: context.date)))
                            .font(.system(size: 30, weight: .bold, design: .rounded).monospacedDigit())
                            .contentTransition(.numericText(countsDown: true))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }

                    Text(pomodoro.isRunning ? pomodoro.phase.title.uppercased() : (pomodoro.isIdle ? "Pomodoro" : "PAUSED"))
                        .font(.headline).fontWeight(.medium).lineLimit(1).minimumScaleFactor(0.7)
                        .foregroundColor(pomodoro.isIdle ? .secondary : pomodoro.phase.accent)

                    sessionDots
                }
                .layoutPriority(1)
            }

            VStack(alignment: .trailing, spacing: 6) {
                CompactInfoRow(iconName: "checkmark.seal.fill", value: "\(pomodoro.completedToday) today")
                HStack(spacing: 6) {
                    Button(action: pomodoro.reset) { Image(systemName: "arrow.counterclockwise") }
                        .buttonStyle(CircleIconButtonStyle(type: .normal, size: .small))
                        .help("Restart this phase")
                    Button(action: pomodoro.toggle) { Image(systemName: pomodoro.isRunning ? "pause.fill" : "play.fill") }
                        .buttonStyle(CircleIconButtonStyle(type: .normal, size: .small))
                    Button(action: pomodoro.skip) { Image(systemName: "forward.end.fill") }
                        .buttonStyle(CircleIconButtonStyle(type: .normal, size: .small))
                        .help("Skip to the next phase")
                }
            }
        }
        .padding(.horizontal, 10)
        .frame(minWidth: 220, minHeight: 90)
        .fixedSize()
        .foregroundColor(.white)
        .contentShape(Rectangle())
        .contextMenu {
            Button("Reset Cycle", action: pomodoro.resetCycle)
        }
        .animation(.default, value: pomodoro.phase)
        .animation(.default, value: pomodoro.isRunning)
    }

    private var sessionDots: some View {
        HStack(spacing: 4) {
            ForEach(0..<pomodoro.sessionsBeforeLongBreak, id: \.self) { index in
                Circle()
                    .fill(index < pomodoro.completedInCycle ? pomodoro.phase.accent : Color.white.opacity(0.18))
                    .frame(width: 6, height: 6)
            }
        }
    }
}

private struct PomodoroRing: View {
    @ObservedObject var pomodoro: PomodoroManager

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            ZStack {
                ProgressRingView(
                    progress: pomodoro.progress(at: context.date),
                    lineWidth: 4,
                    active: AnyShapeStyle(
                        AngularGradient(colors: pomodoro.phase.colors + [pomodoro.phase.colors[0]], center: .center)
                    ),
                    activeShadow: (pomodoro.phase.accent.opacity(pomodoro.isRunning ? 0.45 : 0), 6)
                )
                Image(systemName: pomodoro.isRunning ? pomodoro.phase.symbol : "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(pomodoro.phase.accent)
                    .shadow(color: pomodoro.phase.accent.opacity(0.45), radius: 6)
            }
        }
        .frame(width: 44, height: 44)
    }
}

// MARK: - To-dos

struct TodoWidgetView: View {
    @ObservedObject private var store = TodoStore.shared
    @State private var draft = ""
    @State private var isAdding = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            if isAdding {
                NotchSearchField(placeholder: "New task", text: $draft, onSubmit: submit, autofocus: true)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(MaterialChartPalette.surfaceContainer)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            let visible = Array(store.sorted.prefix(isAdding ? 2 : 3))
            if visible.isEmpty, !isAdding {
                Text("No tasks. Tap + to add one.")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(MaterialChartPalette.onSurfaceVariant)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(visible) { item in row(item) }
                }
            }
        }
        .frame(width: 190, height: 96, alignment: .topLeading)
        .clipped()
    }

    private var header: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(LinearGradient(colors: [.green.opacity(0.35), .teal.opacity(0.25)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 26, height: 26)
                Image(systemName: "checklist")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.green)
            }
            Text("To-dos")
                .font(.system(size: 12, weight: .bold, design: .rounded))
            Spacer(minLength: 0)
            Text("\(store.openCount)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(MaterialChartPalette.onSurfaceVariant)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(MaterialChartPalette.surfaceVariant)
                .clipShape(Capsule())
            Button {
                withAnimation(.snappy(duration: 0.2)) { isAdding.toggle() }
            } label: {
                Image(systemName: isAdding ? "xmark" : "plus")
                    .font(.system(size: 10, weight: .bold))
                    .frame(width: 20, height: 20)
                    .background(MaterialChartPalette.surfaceVariant, in: Circle())
            }
            .buttonStyle(.plain)
            .help(isAdding ? "Cancel" : "Add a task")
        }
    }

    private func row(_ item: TodoItem) -> some View {
        HStack(spacing: 6) {
            Button { store.toggleCompleted(item) } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(item.isCompleted ? Color.green : Color.white.opacity(0.6))
            }
            .buttonStyle(.plain)
            Text(item.title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .strikethrough(item.isCompleted)
                .foregroundStyle(.white.opacity(item.isCompleted ? 0.45 : 0.92))
                .lineLimit(1)
            Spacer(minLength: 0)
            if item.isPriority {
                Image(systemName: "star.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.yellow)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(MaterialChartPalette.surfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .contentShape(Rectangle())
        .contextMenu {
            Button(item.isPriority ? "Remove Star" : "Star") { store.togglePriority(item) }
            Button("Delete", role: .destructive) { store.delete(item) }
            Divider()
            Button("Clear Completed") { store.clearCompleted() }
        }
    }

    private func submit() {
        store.add(draft)
        draft = ""
        withAnimation(.snappy(duration: 0.2)) { isAdding = false }
    }
}

// MARK: - Quick Apps

struct QuickAppsWidgetView: View {
    @ObservedObject private var store = QuickAppsStore.shared
    @State private var isTargeted = false

    /// Two apps per column; the widget grows by columns as more apps are pinned.
    private var columns: [[URL]] {
        let urls = store.urls
        return stride(from: 0, to: urls.count, by: 2).map { Array(urls[$0..<min($0 + 2, urls.count)]) }
    }

    var body: some View {
        Group {
            if store.paths.isEmpty {
                emptyState
            } else {
                HStack(spacing: 6) {
                    ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                        VStack(spacing: 6) {
                            ForEach(column, id: \.self) { url in
                                QuickAppIcon(url: url, isRunning: store.isRunning(url))
                            }
                            if column.count == 1 { Spacer(minLength: 0) }
                        }
                    }
                }
                .padding(.horizontal, 6)
            }
        }
        .frame(height: 96)
        .fixedSize(horizontal: true, vertical: false)
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            for provider in providers {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    guard let url else { return }
                    Task { @MainActor in QuickAppsStore.shared.add([url]) }
                }
            }
            return true
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "plus.app")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.blue.opacity(isTargeted ? 1 : 0.8))
            Text("Drop apps here")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(MaterialChartPalette.onSurfaceVariant)
        }
        .frame(width: 110, height: 90)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                .foregroundStyle(.white.opacity(isTargeted ? 0.6 : 0.2))
        )
        .contentShape(Rectangle())
        .onTapGesture { store.pickApps() }
        .help("Pick apps to pin")
    }
}

private struct QuickAppIcon: View {
    let url: URL
    let isRunning: Bool
    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 2) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                .resizable()
                .interpolation(.high)
                .frame(width: 38, height: 38)
                .scaleEffect(isHovering ? 1.12 : 1)
                .shadow(color: .black.opacity(0.4), radius: isHovering ? 4 : 0, y: 2)
            Circle()
                .fill(Color.white.opacity(isRunning ? 0.75 : 0))
                .frame(width: 3, height: 3)
        }
        .frame(width: 44, height: 45)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { isHovering = hovering }
        }
        .onTapGesture { QuickAppsStore.shared.launch(url) }
        .help(QuickAppsStore.displayName(url))
        .contextMenu {
            Button("Open") { QuickAppsStore.shared.launch(url) }
            Button("Show in Finder") { NSWorkspace.shared.activateFileViewerSelecting([url]) }
            Divider()
            Button("Remove", role: .destructive) { QuickAppsStore.shared.remove(url) }
        }
    }
}
