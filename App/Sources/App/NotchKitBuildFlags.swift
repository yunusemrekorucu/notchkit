//
//  NotchKitBuildFlags.swift
//  NotchKit
//
//  Created by Shariq Charolia on 2026-08-10

import Foundation

enum NotchKitBuildFlags {
    static var forceOnboarding: Bool {
        #if NOTCHKIT_FORCE_ONBOARDING
        return true
        #else
        return false
        #endif
    }
}

enum OnboardingLaunchPolicy {
    static var shouldShowOnboarding: Bool {
        if NotchKitBuildFlags.forceOnboarding {
            return true
        }
        if UserDefaults.standard.bool(forKey: "forceOnboarding") {
            return true
        }
        return !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
}