import SwiftUI
import EventKit
import Defaults

@MainActor
final class CalendarStore: ObservableObject {
    static let shared = CalendarStore()
    let store = EKEventStore()
    @Published var authorized = false
    @Published var events: [EKEvent] = []

    init() {
        authorized = EKEventStore.authorizationStatus(for: .event) == .fullAccess
        NotificationCenter.default.addObserver(forName: .EKEventStoreChanged, object: store, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.reload() }
        }
        if authorized { reload() }
    }

    func requestAccess() {
        Task {
            let granted = (try? await store.requestFullAccessToEvents()) ?? false
            authorized = granted
            if granted { reload() }
        }
    }

    func reload() {
        guard authorized else { return }
        let start = Calendar.current.startOfDay(for: .now)
        let end = Calendar.current.date(byAdding: .day, value: Defaults[.calendarDaysAhead] + 1, to: start)!
        let selected = Set(Defaults[.selectedCalendars])
        let calendars = store.calendars(for: .event).filter { selected.isEmpty || selected.contains($0.calendarIdentifier) }
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: calendars)
        events = store.events(matching: predicate)
            .filter { Defaults[.calendarShowAllDay] || !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }
    }

    func events(on day: Date) -> [EKEvent] {
        events.filter { Calendar.current.isDate($0.startDate, inSameDayAs: day) }
    }

    /// Önümüzdeki 15 dakika içinde başlayan ya da şu an süren etkinlik.
    var upcoming: EKEvent? {
        let now = Date.now
        return events.first { !$0.isAllDay && $0.endDate > now && $0.startDate.timeIntervalSince(now) < 15 * 60 }
    }
}

enum MeetingService: String {
    case meet, zoom, teams, webex

    static func detect(in event: EKEvent) -> (MeetingService, URL)? {
        let haystack = [event.url?.absoluteString, event.location, event.notes].compactMap { $0 }.joined(separator: " ")
        let patterns: [(MeetingService, String)] = [
            (.meet, #"https://meet\.google\.com/[a-z\-]+"#),
            (.zoom, #"https://[\w\.]*zoom\.us/[jw]/[\w\?=\-&]+"#),
            (.teams, #"https://teams\.microsoft\.com/l/meetup-join/[^\s>]+"#),
            (.webex, #"https://[\w\.]*webex\.com/[^\s>]+"#),
        ]
        for (service, pattern) in patterns {
            if let range = haystack.range(of: pattern, options: .regularExpression),
               let url = URL(string: String(haystack[range])) { return (service, url) }
        }
        return nil
    }
}

extension Locale {
    static let turkish = Locale(identifier: "tr_TR")
}

struct CalendarWidget: View {
    @ObservedObject private var store = CalendarStore.shared
    @State private var selectedDay = Calendar.current.startOfDay(for: .now)
    @Default(.calendarDaysAhead) private var daysAhead

    private let daysBehind = 3
    private var today: Date { Calendar.current.startOfDay(for: .now) }
    private var days: [Date] {
        (-daysBehind...daysAhead).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: today) }
    }

    var body: some View {
        if store.authorized {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    monthLabel
                    dayStrip
                }
                .frame(height: 42)

                eventList
            }
        } else {
            permissionView
        }
    }

    // MARK: Başlık

    private var monthLabel: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(selectedDay.formatted(.dateTime.month(.wide).locale(.turkish)).capitalized(with: .turkish))
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
            Text(selectedDay.formatted(.dateTime.year().locale(.turkish)))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.45))
            if !Calendar.current.isDate(selectedDay, inSameDayAs: today) {
                Button {
                    withAnimation(.snappy) { selectedDay = today }
                } label: {
                    Text("Bugün")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 50, alignment: .leading)
    }

    // MARK: Gün şeridi

    private var dayStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(days, id: \.self) { day in
                        DayCell(day: day,
                                isSelected: Calendar.current.isDate(day, inSameDayAs: selectedDay),
                                isToday: Calendar.current.isDate(day, inSameDayAs: today),
                                hasEvents: !store.events(on: day).isEmpty)
                            .id(day)
                            .onTapGesture { withAnimation(.snappy) { selectedDay = day } }
                    }
                }
                .padding(.horizontal, 6)
            }
            .mask(
                LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.08),
                                       .init(color: .black, location: 0.92), .init(color: .clear, location: 1)],
                               startPoint: .leading, endPoint: .trailing))
            .onAppear { proxy.scrollTo(selectedDay, anchor: .center) }
            .onChange(of: selectedDay) { _, day in
                withAnimation(.snappy) { proxy.scrollTo(day, anchor: .center) }
            }
        }
    }

    // MARK: Etkinlikler

    @ViewBuilder
    private var eventList: some View {
        let events = store.events(on: selectedDay)
        if events.isEmpty {
            HStack(spacing: 6) {
                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 12))
                Text(Calendar.current.isDate(selectedDay, inSameDayAs: today) ? "Bugün etkinlik yok" : "Bu gün etkinlik yok")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(.white.opacity(0.4))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.white.opacity(0.04)))
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 4) {
                    ForEach(events, id: \.eventIdentifier) { EventRow(event: $0) }
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    private var permissionView: some View {
        VStack(spacing: 6) {
            Image(systemName: "calendar")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.red)
            Text("Etkinliklerini görmek için takvim izni ver")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            Button { store.requestAccess() } label: {
                Text("İzin ver")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 12).padding(.vertical, 4)
                    .background(Capsule().fill(.white))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct DayCell: View {
    let day: Date
    let isSelected: Bool
    let isToday: Bool
    let hasEvents: Bool
    @State private var hovering = false

    private var isWeekend: Bool { Calendar.current.isDateInWeekend(day) }

    var body: some View {
        VStack(spacing: 2) {
            Text(day.formatted(.dateTime.weekday(.abbreviated).locale(.turkish)).uppercased(with: .turkish))
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(isSelected ? .black.opacity(0.6)
                                 : isWeekend ? Color(red: 0.925, green: 0.643, blue: 0.612) : .white.opacity(0.45))
            Text(day.formatted(.dateTime.day()))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? .black : isToday ? .red : .white)
            Circle()
                .fill(hasEvents ? (isSelected ? Color.black.opacity(0.6) : .white.opacity(0.5)) : .clear)
                .frame(width: 3, height: 3)
        }
        .frame(width: 30, height: 42)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(isSelected ? Color.white : .white.opacity(hovering ? 0.1 : 0)))
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
    }
}

struct EventRow: View {
    let event: EKEvent
    @State private var hovering = false

    private var color: Color { Color(cgColor: event.calendar.cgColor) }
    private var isOngoing: Bool { !event.isAllDay && event.startDate <= .now && event.endDate > .now }

    var body: some View {
        HStack(spacing: 8) {
            Capsule().fill(color).frame(width: 3, height: 20)
            VStack(alignment: .leading, spacing: 0) {
                Text(event.title ?? "Etkinlik")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(timeText)
                    .font(.system(size: 9.5, weight: .medium).monospacedDigit())
                    .foregroundStyle(isOngoing ? color : .white.opacity(0.5))
            }
            Spacer(minLength: 4)
            if let (_, url) = MeetingService.detect(in: event) {
                Button { NSWorkspace.shared.open(url) } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "video.fill").font(.system(size: 8))
                        Text("Katıl").font(.system(size: 9.5, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Capsule().fill(Color.blue))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 6)
        .frame(height: 28)
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(color.opacity(hovering ? 0.22 : 0.12)))
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .onTapGesture {
            if let id = event.calendarItemExternalIdentifier?.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
               let url = URL(string: "ical://ekevent/\(id)?method=show&options=more") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    private var timeText: String {
        if event.isAllDay { return "Tüm gün" }
        let start = event.startDate.formatted(.dateTime.hour().minute().locale(.turkish))
        let end = event.endDate.formatted(.dateTime.hour().minute().locale(.turkish))
        return isOngoing ? "Şimdi · \(end)'e kadar" : "\(start) – \(end)"
    }
}
