//
//  BluetoothAddress.swift
//  NotchKit
//
//  Bluetooth address helpers and a log sink for the earbud clients.

import Foundation
import os.log

enum ContinuityBluetoothAddress {
    /// Lower-case, colon-separated form ("aa:bb:cc:dd:ee:ff"), or nil if the input is not a MAC address.
    static func normalize(_ address: String?) -> String? {
        guard let address else { return nil }
        let hex = address.lowercased().filter { $0.isHexDigit }
        guard hex.count == 12 else { return nil }
        var pairs: [String] = []
        var index = hex.startIndex
        for _ in 0..<6 {
            let next = hex.index(index, offsetBy: 2)
            pairs.append(String(hex[index..<next]))
            index = next
        }
        return pairs.joined(separator: ":")
    }

    /// Dash-separated form used by IOBluetooth ("aa-bb-cc-dd-ee-ff").
    static func dashed(_ address: String?) -> String? {
        normalize(address)?.replacingOccurrences(of: ":", with: "-")
    }

    static func matches(_ lhs: String?, _ rhs: String?) -> Bool {
        guard let left = normalize(lhs), let right = normalize(rhs) else { return false }
        return left == right
    }
}

enum ContinuityLog {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "NotchKit", category: "Earbuds")
    static func f(_ message: String) { logger.debug("\(message, privacy: .public)") }
    static func fErr(_ message: String) { logger.error("\(message, privacy: .public)") }
}
