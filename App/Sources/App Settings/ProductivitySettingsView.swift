//
//  ProductivitySettingsView.swift
//  NotchKit
//
//  Settings for the Pomodoro, To-dos and Quick Apps widgets.

import AppKit
import SwiftUI

struct ProductivitySettingsView: View {
    @EditingSettings var settings: SettingsEditingSession
    @ObservedObject private var pomodoro = PomodoroManager.shared
    @ObservedObject private var todos = TodoStore.shared
    @ObservedObject private var quickApps = QuickAppsStore.shared

    @AppStorage(PomodoroManager.Key.focus) private var focusMinutes = 25
    @AppStorage(PomodoroManager.Key.shortBreak) private var shortBreakMinutes = 5
    @AppStorage(PomodoroManager.Key.longBreak) private var longBreakMinutes = 15
    @AppStorage(PomodoroManager.Key.sessions) private var sessions = 4
    @AppStorage(PomodoroManager.Key.autoStart) private var autoStart = false
    @AppStorage(PomodoroManager.Key.playSound) private var playSound = true
    @AppStorage(TodoStore.showCompletedKey) private var showCompleted = true

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                Text("Pomodoro & Tasks")
                    .font(.largeTitle.bold())
                    .padding(.bottom)

                pomodoroSection
                todoSection
                quickAppsSection
            }
            .padding(25)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    // MARK: Pomodoro

    private var pomodoroSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Pomodoro").font(.headline).padding([.top, .horizontal])
            ToggleRow(
                title: "Show Pomodoro Widget",
                description: "A focus timer with short and long breaks in the notch.",
                isOn: $settings.settings.pomodoroWidgetEnabled
            )
            Divider().padding(.leading, 20)
            minutesRow("Focus", value: $focusMinutes, range: 1...120)
            Divider().padding(.leading, 20)
            minutesRow("Short Break", value: $shortBreakMinutes, range: 1...60)
            Divider().padding(.leading, 20)
            minutesRow("Long Break", value: $longBreakMinutes, range: 1...90)
            Divider().padding(.leading, 20)
            HStack {
                SettingsRowLabel(title: "Sessions Before Long Break")
                Spacer()
                Stepper("\(sessions)", value: $sessions, in: 1...12)
                    .monospacedDigit()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            Divider().padding(.leading, 20)
            ToggleRow(title: "Start Next Phase Automatically", description: "Begin the break or the next focus session as soon as the timer ends.", isOn: $autoStart)
            Divider().padding(.leading, 20)
            ToggleRow(title: "Play a Sound When a Phase Ends", isOn: $playSound)
        }
        .modifier(SettingsContainerModifier())
        .onChange(of: focusMinutes) { pomodoro.durationsChanged() }
        .onChange(of: shortBreakMinutes) { pomodoro.durationsChanged() }
        .onChange(of: longBreakMinutes) { pomodoro.durationsChanged() }
    }

    private func minutesRow(_ title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack {
            SettingsRowLabel(title: title)
            Spacer()
            Stepper("\(value.wrappedValue) min", value: value, in: range)
                .monospacedDigit()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: To-dos

    private var todoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("To-dos").font(.headline).padding([.top, .horizontal])
            ToggleRow(
                title: "Show To-dos Widget",
                description: "A quick task list with stars. Tap + in the widget to add a task.",
                isOn: $settings.settings.todoWidgetEnabled
            )
            Divider().padding(.leading, 20)
            ToggleRow(title: "Show Completed Tasks", isOn: $showCompleted)
            Divider().padding(.leading, 20)
            HStack {
                SettingsRowLabel(title: "Tasks", description: "\(todos.openCount) open, \(todos.items.count - todos.openCount) completed")
                Spacer()
                Button("Clear Completed") { todos.clearCompleted() }
                    .disabled(todos.items.allSatisfy { !$0.isCompleted })
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .modifier(SettingsContainerModifier())
    }

    // MARK: Quick Apps

    private var quickAppsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Quick Apps").font(.headline).padding([.top, .horizontal])
            ToggleRow(
                title: "Show Quick Apps Widget",
                description: "Pin apps and open them in one click. A dot marks apps that are running.",
                isOn: $settings.settings.quickAppsWidgetEnabled
            )
            Divider().padding(.leading, 20)
            ForEach(quickApps.urls, id: \.self) { url in
                HStack(spacing: 12) {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                        .resizable()
                        .frame(width: 28, height: 28)
                    Text(QuickAppsStore.displayName(url))
                    Spacer()
                    Button {
                        quickApps.remove(url)
                    } label: {
                        Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .help("Remove")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                Divider().padding(.leading, 20)
            }
            HStack {
                Spacer()
                Button("Add Apps…") { quickApps.pickApps() }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .modifier(SettingsContainerModifier())
    }
}
