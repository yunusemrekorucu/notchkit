//
//  DevActivityLiveActivityView.swift
//  NotchKit
//
//  Created by Shariq Charolia on 2026-09-12
//

import SwiftUI

struct DevActivityLiveActivityView {

    static func left(for task: DevTask) -> some View {
        DevActivityBadgeStack(primary: task)
    }

    static func right(for task: DevTask, additionalCount: Int) -> some View {
        HStack(spacing: 7) {
            Image(systemName: "waveform")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color(nsColor: NSColor(task.tool.tint).blended(withFraction: 0.55, of: .white) ?? .white))
                .symbolEffect(.variableColor.iterative, options: .repeating)

            if additionalCount > 0 {
                Text("\(additionalCount + 1)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .frame(height: 16)
                    .background(Capsule().fill(Color.white.opacity(0.16)))
                    .transition(.scale.combined(with: .opacity))
                    .help("\(additionalCount + 1) tasks running")
            }

            DevActivityElapsedLabel(startedAt: task.startedAt, tint: .white)
        }
        .animation(.snappy(duration: 0.25), value: additionalCount)
    }
}

/// The running tools as rounded-square badges. With several tasks, up to three badges
/// overlap so the count reads at a glance; the primary task's badge sits in front.
private struct DevActivityBadgeStack: View {
    let primary: DevTask
    @ObservedObject private var monitor = DevActivityMonitor.shared

    private static let badgeSize: CGFloat = 20
    private static let overlap: CGFloat = 13

    private var tools: [DevTool] {
        var seen = Set<String>([primary.tool.id])
        var result = [primary.tool]
        for task in monitor.tasks where seen.insert(task.tool.id).inserted {
            result.append(task.tool)
            if result.count == 3 { break }
        }
        return result
    }

    var body: some View {
        let tools = tools
        ZStack(alignment: .leading) {
            ForEach(Array(tools.enumerated().reversed()), id: \.element.id) { index, tool in
                DevActivityBadge(tool: tool, isPrimary: index == 0)
                    .offset(x: CGFloat(index) * Self.overlap)
                    .zIndex(Double(tools.count - index))
            }
        }
        .frame(
            width: Self.badgeSize + CGFloat(tools.count - 1) * Self.overlap,
            height: Self.badgeSize,
            alignment: .leading
        )
        .animation(.snappy(duration: 0.25), value: tools.map(\.id))
    }
}

private struct DevActivityBadge: View {
    let tool: DevTool
    let isPrimary: Bool

    var body: some View {
        ZStack {
            if isPrimary {
                DevActivityPulseCircle(color: NSColor(tool.tint.opacity(0.35)))
                    .frame(width: 26, height: 26)
            }
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [tool.tint.opacity(0.95), tool.tint.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.55), lineWidth: isPrimary ? 0 : 1.5)
                )
                .frame(width: 20, height: 20)
            Image(systemName: tool.symbol)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: 20, height: 20)
        .opacity(isPrimary ? 1 : 0.85)
    }
}

private struct DevActivityPulseCircle: NSViewRepresentable {
    let color: NSColor

    func makeNSView(context: Context) -> DevActivityPulseView {
        let view = DevActivityPulseView()
        view.color = color
        return view
    }

    func updateNSView(_ nsView: DevActivityPulseView, context: Context) {
        nsView.color = color
    }
}

private final class DevActivityPulseView: NSView {
    private static let animationKey = "breathing"
    private let circle = CALayer()

    var color: NSColor = .clear {
        didSet {
            guard color != oldValue else { return }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            circle.backgroundColor = color.cgColor
            CATransaction.commit()
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.addSublayer(circle)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        circle.bounds = CGRect(origin: .zero, size: bounds.size)
        circle.position = CGPoint(x: bounds.midX, y: bounds.midY)
        circle.cornerRadius = min(bounds.width, bounds.height) / 2
        circle.backgroundColor = color.cgColor
        CATransaction.commit()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil {
            circle.removeAnimation(forKey: Self.animationKey)
        } else {
            startPulse()
        }
    }

    private func startPulse() {
        guard circle.animation(forKey: Self.animationKey) == nil else { return }

        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 0.92
        scale.toValue = 1.12

        let opacity = CABasicAnimation(keyPath: "opacity")
        opacity.fromValue = 0.9
        opacity.toValue = 0.45

        let pulse = CAAnimationGroup()
        pulse.animations = [scale, opacity]
        pulse.duration = 1.1
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulse.preferredFrameRateRange = CAFrameRateRange(minimum: 15, maximum: 30, preferred: 30)
        circle.add(pulse, forKey: Self.animationKey)
    }
}

private struct DevActivityElapsedLabel: View {
    let startedAt: Date
    let tint: Color

    private static let font = NSFont.monospacedSystemFont(ofSize: 11, weight: .semibold)

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            LayerNumericText(
                text: DevTaskFormatting.elapsed(context.date.timeIntervalSince(startedAt)),
                font: Self.font,
                color: NSColor(tint.opacity(0.95))
            )
            .textBaseline()
        }
        .frame(minWidth: 34, alignment: .trailing)
    }
}