import SwiftUI

enum SettingsTab: Hashable { case general, nook, widgets, tray, liveActivities, about }

@MainActor
final class SettingsNavigation: ObservableObject {
    static let shared = SettingsNavigation()
    @Published var tab: SettingsTab = .general
    @Published var selectedWidget: NookWidget = .media
}
