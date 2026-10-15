import Foundation
import IOKit.ps
import Combine

/// Güç kaynağını izler; şarj kablosu takıldığında kısa süreli "şarj" canlı aktivitesi gösterir.
@MainActor
final class BatteryMonitor: ObservableObject {
    static let shared = BatteryMonitor()

    @Published private(set) var level: Int = 100
    @Published private(set) var isCharging = false
    @Published private(set) var isPluggedIn = false
    @Published private(set) var hasBattery = false
    @Published private(set) var showChargingActivity = false

    private var runLoopSource: CFRunLoopSource?
    private var hideWork: DispatchWorkItem?

    func start() {
        refresh(initial: true)
        let context = Unmanaged.passUnretained(self).toOpaque()
        if let source = IOPSNotificationCreateRunLoopSource({ context in
            guard let context else { return }
            let monitor = Unmanaged<BatteryMonitor>.fromOpaque(context).takeUnretainedValue()
            Task { @MainActor in monitor.refresh(initial: false) }
        }, context)?.takeRetainedValue() {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
            runLoopSource = source
        }
    }

    private func refresh(initial: Bool) {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else { return }
        let wasPluggedIn = isPluggedIn
        for source in list {
            guard let d = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any],
                  (d[kIOPSTypeKey] as? String) == kIOPSInternalBatteryType else { continue }
            hasBattery = true
            let current = d[kIOPSCurrentCapacityKey] as? Int ?? 0
            let max = d[kIOPSMaxCapacityKey] as? Int ?? 100
            level = max > 0 ? Int((Double(current) / Double(max) * 100).rounded()) : current
            isCharging = d[kIOPSIsChargingKey] as? Bool ?? false
            isPluggedIn = (d[kIOPSPowerSourceStateKey] as? String) == kIOPSACPowerValue
        }
        if !initial, isPluggedIn != wasPluggedIn {
            flashChargingActivity()
        }
    }

    private func flashChargingActivity() {
        hideWork?.cancel()
        showChargingActivity = true
        let work = DispatchWorkItem { [weak self] in
            Task { @MainActor in self?.showChargingActivity = false }
        }
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: work)
    }
}
