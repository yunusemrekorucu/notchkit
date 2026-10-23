//
//  CircleToSearchManager.swift
//  NotchKit
//
//  Created by Shariq Charolia on 2026-08-30

#if !NOTCHKIT_FULL_BUILD
import Foundation

final class CircleToSearchManager {
    static let shared = CircleToSearchManager()
    private init() {}

    func endResultsPresentation() {}
}

extension Notification.Name {
    static let notchKitOpenCircleToSearch = Notification.Name("notchKitOpenCircleToSearch")
}
#endif