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
            try await scheduleAllNotifications()
            dailyNotificationStatus = .scheduled
        } catch {
            dailyNotificationStatus = .failed
        }
    }

    private func prepareDailyNotificationIfAllowed() async {
        switch await notificationScheduler.authorizationState() {
        case .authorized:
            do {
                try await scheduleAllNotifications()
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

    // .claude/D_screens.md 通知スケジュール全種別を一括登録
    private func scheduleAllNotifications() async throws {
        try await notificationScheduler.scheduleDailyWord(shikigamiID: user.shikigamiId)
        try await notificationScheduler.scheduleWeeklyFortune(shikigamiID: user.shikigamiId)
        try await notificationScheduler.scheduleMonthlyCalendar(shikigamiID: user.shikigamiId)
        try await notificationScheduler.scheduleBirthdayNotification(birthDate: user.birthDate, shikigamiID: user.shikigamiId)
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
    // .claude/D_screens.md プッシュ通知スケジュール準拠
    func scheduleDailyWord(shikigamiID: Int?) async throws
    func scheduleWeeklyFortune(shikigamiID: Int?) async throws
    func scheduleMonthlyCalendar(shikigamiID: Int?) async throws
    func scheduleBirthdayNotification(birthDate: Date?, shikigamiID: Int?) async throws
}

final class DailyNotificationManager: DailyNotificationScheduling {
    private static let requestIDPrefix = "daily_shikigami_word"
    private static let weeklyIDPrefix  = "weekly_fortune"
    private static let monthlyIDPrefix = "monthly_calendar"
    private static let birthdayIDPrefix = "birthday_fortune"
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

    // MARK: - 週次通知（毎週月曜）

    func scheduleWeeklyFortune(shikigamiID: Int?) async throws {
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(Self.weeklyIDPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)

        for weekOffset in 0..<8 {
            guard let fireDate = nextMonday(after: .now, offsetWeeks: weekOffset) else { continue }
            let content = UNMutableNotificationContent()
            content.title = NSLocalizedString("notification.weekly.title", comment: "")
            content.body = NSLocalizedString("notification.weekly.body", comment: "")
            content.sound = .default
            var dc = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear, .weekday, .hour, .minute], from: fireDate)
            dc.weekday = 2  // 月曜
            dc.hour = 8
            dc.minute = 0
            dc.timeZone = TimeZone(identifier: "Asia/Tokyo")
            let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: false)
            let req = UNNotificationRequest(identifier: "\(Self.weeklyIDPrefix).\(weekOffset)", content: content, trigger: trigger)
            try await center.add(req)
        }
    }

    // MARK: - 月次通知（毎月 1 日）

    func scheduleMonthlyCalendar(shikigamiID: Int?) async throws {
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(Self.monthlyIDPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)

        for monthOffset in 0..<3 {
            guard let fireDate = firstDayOfMonth(from: .now, offset: monthOffset) else { continue }
            var dc = calendar.dateComponents([.year, .month], from: fireDate)
            dc.day = 1
            dc.hour = 8
            dc.minute = 0
            dc.timeZone = TimeZone(identifier: "Asia/Tokyo")
            // 配信日時（JST 8:00）がすでに過去の場合はスキップ
            var jstCal = calendar
            jstCal.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
            guard let notificationDate = jstCal.date(from: dc), notificationDate > .now else { continue }
            let content = UNMutableNotificationContent()
            content.title = NSLocalizedString("notification.monthly.title", comment: "")
            content.body = NSLocalizedString("notification.monthly.body", comment: "")
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: false)
            let req = UNNotificationRequest(identifier: "\(Self.monthlyIDPrefix).\(monthOffset)", content: content, trigger: trigger)
            try await center.add(req)
        }
    }

    // MARK: - 誕生日通知

    func scheduleBirthdayNotification(birthDate: Date?, shikigamiID: Int?) async throws {
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(Self.birthdayIDPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)

        guard let birthDate else { return }
        let bdc = calendar.dateComponents([.month, .day], from: birthDate)
        guard let month = bdc.month, let day = bdc.day else { return }

        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notification.birthday.title", comment: "")
        content.body = NSLocalizedString("notification.birthday.body", comment: "")
        content.sound = .default
        var dc = DateComponents()
        dc.month = month
        dc.day = day
        dc.hour = 8
        dc.minute = 0
        dc.timeZone = TimeZone(identifier: "Asia/Tokyo")
        // 次の誕生日に一度だけ送る（repeats: true にすると毎年繰り返す）
        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        let req = UNNotificationRequest(identifier: Self.birthdayIDPrefix, content: content, trigger: trigger)
        try await center.add(req)
    }

    // MARK: - ヘルパー

    private func nextMonday(after date: Date, offsetWeeks: Int) -> Date? {
        var components = DateComponents()
        components.weekday = 2  // 月曜
        components.hour = 8
        components.minute = 0
        guard let first = calendar.nextDate(after: date, matching: components, matchingPolicy: .nextTime) else { return nil }
        return calendar.date(byAdding: .weekOfYear, value: offsetWeeks, to: first)
    }

    private func firstDayOfMonth(from date: Date, offset: Int) -> Date? {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
              let offsetDate = calendar.date(byAdding: .month, value: offset, to: monthStart) else { return nil }
        return calendar.date(bySetting: .day, value: 1, of: offsetDate)
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
