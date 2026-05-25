import Foundation
import Observation
import UserNotifications

@MainActor
@Observable
final class HomeViewModel {
    var todayFortune: Fortune?
    var recentHistory: [Fortune] = []
    var isLoading = false
    var tier: SubscriptionTier = .free
    var dailyNotificationStatus: DailyNotificationStatus = .unknown

    private let user: AppUser
    private let fortuneRepo: FortuneRepository
    private let revenueCat: RevenueCatManager
    private let notificationScheduler: DailyNotificationScheduling

    init(
        user: AppUser,
        fortuneRepo: FortuneRepository,
        revenueCat: RevenueCatManager = .shared,
        notificationScheduler: DailyNotificationScheduling = DailyNotificationManager()
    ) {
        self.user = user
        self.fortuneRepo = fortuneRepo
        self.revenueCat = revenueCat
        self.notificationScheduler = notificationScheduler
    }

    func onAppear() async {
        isLoading = true
        defer { isLoading = false }

        async let historyTask = fortuneRepo.fetchHistory(limit: 3)
        async let tierTask = revenueCat.fetchTier()

        recentHistory = (try? await historyTask) ?? []
        tier = await tierTask

        // 当日の最新鑑定を today fortune として表示
        let todayStart = Calendar.current.startOfDay(for: .now)
        todayFortune = recentHistory.first { $0.createdAt >= todayStart }

        await prepareDailyNotificationIfAllowed()
    }

    func enableDailyNotification() async {
        dailyNotificationStatus = .scheduling

        do {
            guard try await notificationScheduler.requestAuthorization() else {
                dailyNotificationStatus = .denied
                return
            }
            try await notificationScheduler.scheduleDailyWord(shikigamiID: user.shikigamiId)
            dailyNotificationStatus = .scheduled
        } catch {
            dailyNotificationStatus = .failed
        }
    }

    private func prepareDailyNotificationIfAllowed() async {
        switch await notificationScheduler.authorizationState() {
        case .authorized:
            do {
                try await notificationScheduler.scheduleDailyWord(shikigamiID: user.shikigamiId)
                dailyNotificationStatus = .scheduled
            } catch {
                dailyNotificationStatus = .failed
            }
        case .notDetermined:
            dailyNotificationStatus = .needsPermission
        case .denied:
            dailyNotificationStatus = .denied
        }
    }
}

enum DailyNotificationStatus: Equatable {
    case unknown
    case needsPermission
    case scheduling
    case scheduled
    case denied
    case failed

    var showsCard: Bool {
        switch self {
        case .needsPermission, .scheduling, .denied, .failed:
            true
        case .unknown, .scheduled:
            false
        }
    }

    var allowsRequest: Bool {
        switch self {
        case .needsPermission, .failed:
            true
        case .unknown, .scheduling, .scheduled, .denied:
            false
        }
    }
}

enum DailyNotificationAuthorizationState {
    case notDetermined
    case authorized
    case denied
}

protocol DailyNotificationScheduling {
    func authorizationState() async -> DailyNotificationAuthorizationState
    func requestAuthorization() async throws -> Bool
    func scheduleDailyWord(shikigamiID: Int?) async throws
}

final class DailyNotificationManager: DailyNotificationScheduling {
    private static let requestIDPrefix = "daily_shikigami_word"
    private static let scheduledDayCount = 30

    private let center: UNUserNotificationCenter
    private let calendar: Calendar
    private let hour: Int
    private let minute: Int

    init(
        center: UNUserNotificationCenter = .current(),
        calendar: Calendar = .current,
        hour: Int = 8,
        minute: Int = 0
    ) {
        self.center = center
        self.calendar = calendar
        self.hour = hour
        self.minute = minute
    }

    func authorizationState() async -> DailyNotificationAuthorizationState {
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .authorized, .provisional, .ephemeral:
            return .authorized
        case .denied:
            return .denied
        @unknown default:
            return .denied
        }
    }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func scheduleDailyWord(shikigamiID: Int?) async throws {
        let pending = await center.pendingNotificationRequests()
        let requestIDs = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.requestIDPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: requestIDs)

        for fireDate in upcomingFireDates(from: .now) {
            try await center.add(makeRequest(shikigamiID: shikigamiID, fireDate: fireDate))
        }
    }

    private func makeRequest(shikigamiID: Int?, fireDate: Date) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notification.daily.title", comment: "")
        content.body = dailyWordBody(shikigamiID: shikigamiID, date: fireDate)
        content.sound = .default

        let day = calendar.dateComponents([.year, .month, .day], from: fireDate)
        var dateComponents = DateComponents(
            calendar: calendar,
            year: day.year,
            month: day.month,
            day: day.day,
            hour: hour,
            minute: minute
        )
        dateComponents.timeZone = calendar.timeZone

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        return UNNotificationRequest(identifier: requestID(for: fireDate), content: content, trigger: trigger)
    }

    private func dailyWordBody(shikigamiID: Int?, date: Date) -> String {
        let selection = DailyShikigamiWordEngine.selection(
            shikigamiID: shikigamiID,
            date: date,
            calendar: calendar
        )
        let shikigamiName = selection.shikigamiNameKey
            .map { NSLocalizedString($0, comment: "") }
            ?? NSLocalizedString("notification.daily.defaultShikigami", comment: "")
        let word = NSLocalizedString(selection.templateLocalizationKey, comment: "")
        let format = NSLocalizedString("notification.daily.body.format", comment: "")

        return String.localizedStringWithFormat(format, shikigamiName, word)
    }

    private func upcomingFireDates(from now: Date) -> [Date] {
        guard let firstFireDate = calendar.nextDate(
            after: now,
            matching: DateComponents(hour: hour, minute: minute),
            matchingPolicy: .nextTime,
            direction: .forward
        ) else {
            return []
        }

        return (0..<Self.scheduledDayCount).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: firstFireDate)
        }
    }

    private func requestID(for date: Date) -> String {
        let day = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(Self.requestIDPrefix).\(day.year ?? 0).\(day.month ?? 0).\(day.day ?? 0)"
    }
}
