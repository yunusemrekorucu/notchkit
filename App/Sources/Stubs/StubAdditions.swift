//
//  StubAdditions.swift
//  NotchKit
//
//  Members that Sapphire's public code calls but its public stubs do not declare yet.
//  The features behind them (phone continuity, DMG installer, clean links) are not
//  part of NotchKit, so every member does nothing.

import Foundation
import UserNotifications

@MainActor
final class ContinuityNotificationResponder {
    func handleNotificationResponse(_ response: UNNotificationResponse) {}
}

@MainActor
extension ContinuityManager {
    func openWidgets(focus: Int?) {}
    var messagesBridge: ContinuityNotificationResponder { ContinuityNotificationResponder() }
    var callsBridge: ContinuityNotificationResponder { ContinuityNotificationResponder() }
}

@MainActor
extension CleanURLManager {
    func stopMonitoring() {}
}

@MainActor
extension DMGInstallerManager {
    func reconcileDefaultHandlerIfNeeded() {}
}

import SwiftUI

extension ContinuityConnectivitySnapshot.Severity {
    var tint: Color {
        switch self {
        case .noDevice: .white.opacity(0.5)
        case .healthy: .green
        case .degraded: .orange
        case .offline: .red
        }
    }
}

/// Sapphire's quit-protection rule editor is part of its private System Enhance build.
struct SEQuitProtectionRulesView: View {
    var body: some View { EmptyView() }
}
