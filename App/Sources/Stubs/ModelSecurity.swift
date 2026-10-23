//
//  ModelSecurity.swift
//  NotchKit
//
//  Created by Shariq Charolia on 2026-08-30

#if !NOTCHKIT_FULL_BUILD
import Foundation
import CryptoKit

enum ModelSecurity {
    static let encryptionKey = SymmetricKey(data: Data(count: 32))
}
#endif