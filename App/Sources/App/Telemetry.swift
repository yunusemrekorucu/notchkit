//
//  Telemetry.swift
//  NotchKit
//
//  Sapphire ships Firebase analytics, performance traces and a shared Firestore
//  lyrics cache. NotchKit collects nothing, so these keep Sapphire's call sites
//  compiling while doing no work. Based on Sapphire (AGPL-3.0, Shariq Charolia).

import Foundation

@MainActor
enum SapphireAnalytics {
    static var isEnabled: Bool { false }
    static func scheduleBootstrap(after delay: TimeInterval) {}
    static func bootstrap() {}
    static func whenReady(_ work: @escaping @MainActor () -> Void) {}
    static func applyCollectionPreference() {}
    static func logEvent(_ name: String, parameters: [String: Any]? = nil) {}
}

@MainActor
final class SapphirePerformanceTrace {
    @discardableResult func setMetric(_ value: Int64, named metricName: String) -> Self { self }
    @discardableResult func incrementMetric(_ metricName: String, by value: Int64 = 1) -> Self { self }
    @discardableResult func setAttribute(_ value: String, named attributeName: String) -> Self { self }
    func stop() {}
}

@MainActor
enum SapphirePerformance {
    static func setCollectionEnabled(_ enabled: Bool) {}
    static func startTrace(name: String, attributes: [String: String] = [:]) -> SapphirePerformanceTrace? { nil }
    static func recordTrace(
        name: String,
        startTime: Date,
        duration: TimeInterval,
        counters: [String: Int64] = [:],
        attributes: [String: String] = [:]
    ) {}
}

@MainActor
enum FirebaseBootstrap {
    static var isConfigured: Bool { false }
    static func configureIfNeeded() {}
    /// There is no shared lyrics database; callers fall back to their local paths.
    static func firestoreDatabase() -> Firestore? { nil }
}

// Minimal Firestore surface used by the lyrics services. It is never instantiated.
final class Firestore {
    private init() {}
    func collection(_ path: String) -> FirestoreCollection { FirestoreCollection() }
}

struct FirestoreCollection {
    func document(_ path: String) -> FirestoreDocument { FirestoreDocument() }
}

struct FirestoreDocument {
    func getDocument() async throws -> FirestoreSnapshot { FirestoreSnapshot() }
    func setData(_ data: [String: Any]) async throws {}
}

struct FirestoreSnapshot {
    func data() -> [String: Any]? { nil }
}

enum FieldValue {
    static func serverTimestamp() -> Any { Date() }
}

let FirestoreErrorDomain = "FIRFirestoreErrorDomain"

enum FirestoreErrorCode: Int {
    case permissionDenied = 7
}
