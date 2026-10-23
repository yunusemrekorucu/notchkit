//
//  NearbyShareShim.swift
//  NotchKit
//
//  Sapphire links a NearbyShare framework for Android Quick Share. NotchKit does not
//  ship Nearby Share, so this keeps the same API surface with an inert manager that
//  never becomes visible and never reports transfers.
//  Shapes follow Sapphire/Nearby (AGPL-3.0, Shariq Charolia).

import Foundation

extension Notification.Name {
    static let sapphireNearbyFileDownloaded = Notification.Name("SapphireNearbyFileDownloaded")
}

enum TransferDirection { case incoming, outgoing }

enum TransferState { case waiting, inProgress, finished, failed, canceled }

struct TransferProgressInfo: Identifiable, Equatable {
    let id: String
    var deviceName: String
    var fileDescription: String
    var direction: TransferDirection
    var state: TransferState = .waiting
    var progress: Double = 0.0
    var iconName: String = "doc"
}

enum NearbyTransferUserAction { case save, open, copy }

struct RemoteDeviceInfo {
    let name: String
    let type: DeviceType
    let qrCodeData: Data?
    var id: String?

    enum DeviceType: Int32 { case unknown = 0, phone, tablet, computer }
}

enum NearbyError: Error, Equatable {
    case protocolError(_ message: String)
    case requiredFieldMissing(_ message: String)
    case ukey2
    case inputOutput
    case canceled(reason: CancellationReason)

    enum CancellationReason: Equatable {
        case userRejected, userCanceled, notEnoughSpace, unsupportedType, timedOut
    }
}

struct TransferMetadata {
    let files: [NearbyFileMetadata]
    let id: String
    let pinCode: String?
    let textDescription: String?
}

struct NearbyFileMetadata {
    let name: String
    let size: Int64
    let mimeType: String
}

protocol MainAppDelegate: AnyObject {
    func obtainUserConsent(for transfer: TransferMetadata, from device: RemoteDeviceInfo, fileURLs: [URL])
    func incomingTransfer(id: String, didUpdateProgress progress: Double)
    func incomingTransfer(id: String, didFinishWith error: Error?)
}

final class NearbyConnectionManager: NSObject, ObservableObject {
    static let shared = NearbyConnectionManager()

    weak var mainAppDelegate: (any MainAppDelegate)?
    @Published var transfers: [TransferProgressInfo] = []
    var deviceDisplayName: String = Host.current().localizedName ?? "My Mac"

    func becomeVisible() {}
    func becomeInvisible() {}
    func submitUserConsent(transferID: String, accept: Bool, action: NearbyTransferUserAction = .save) {}
    func cancelIncomingTransfer(id: String) {}
    func cancelOutgoingTransfer(id: String) {}
    func startDeviceDiscovery() {}
    func stopDeviceDiscovery() {}
}
