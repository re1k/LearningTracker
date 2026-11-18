import Foundation
import SwiftData

#if DEBUG

struct SeedData {

    @discardableResult
    static func createIfNeeded(
        in context: ModelContext,
        target: Target
    ) -> Bool {

        // MARK: - Check Existing Logs

        let descriptor = FetchDescriptor<DailyLog>()

        let existingLogs = (try? context.fetch(descriptor)) ?? []

        // Don't seed if logs already exist
        guard existingLogs.isEmpty else {
            print("DEBUG: Seed data already exists")
            return false
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // MARK: - Three Calendar Months

        guard let currentMonth = calendar.dateInterval(
            of: .month,
            for: today
        )?.start,
        let startMonth = calendar.date(
            byAdding: .month,
            value: -2,
            to: currentMonth
        ) else {
            return false
        }

        // Set calendar history start date
        UserDefaults.standard.set(
            startMonth,
            forKey: "appStartDate"
        )

        // MARK: - Generate Past Logs

        guard let yesterday = calendar.date(
            byAdding: .day,
            value: -1,
            to: today
        ) else {
            return false
        }

        let numberOfDays = calendar.dateComponents(
            [.day],
            from: startMonth,
            to: yesterday
        ).day ?? 0

        var generatedLogs: [DailyLog] = []

        guard numberOfDays > 0 else {
            return false
        }

        for daysAgo in 1...numberOfDays {

            guard let date = calendar.date(
                byAdding: .day,
                value: -daysAgo,
                to: today
            ) else {
                continue
            }

            let status = generateStatus(daysAgo: daysAgo)

            let log = DailyLog(
                dayDate: date,
                logStatus: status
            )

            context.insert(log)
            generatedLogs.append(log)
        }

        // MARK: - Calculate Counters

        var currentStreak = 0

        for log in generatedLogs.sorted(
            by: { $0.dayDate > $1.dayDate }
        ) {

            switch log.logStatus {

            case .streak:
                currentStreak += 1

            case .freeze:
                continue

            case .skip:
                break
            }

            if log.logStatus == .skip {
                break
            }
        }

        target.streakCounter = currentStreak

        target.freezeCounter = generatedLogs.filter {
            $0.logStatus == .freeze &&
            (calendar.dateComponents(
                [.day],
                from: $0.dayDate,
                to: today
            ).day ?? 999) <= target.duration
        }.count

        // MARK: - Save

        do {
            try context.save()

            print("DEBUG: Historical seed data created!")
            print("DEBUG: Logs:", generatedLogs.count)
            print("DEBUG: Streak:", target.streakCounter)
            print("DEBUG: Freezes:", target.freezeCounter)

            return true

        } catch {
            print("DEBUG: Seed failed:", error)
            return false
        }
    }

    // MARK: - Generate Status Pattern

    private static func generateStatus(daysAgo: Int) -> LogStatus {

        switch daysAgo {

        case 1...5:
            return .streak

        case 6:
            return .freeze

        case 7...12:
            return .streak

        case 13:
            return .skip

        case 14...18:
            return .streak

        case 19:
            return .skip

        case 20:
            return .freeze

        case 21...28:
            return .streak

        case 29:
            return .skip

        case 30...35:
            return .streak

        case 36:
            return .freeze

        case 37...45:
            return .streak

        case 46:
            return .skip

        case 47...55:
            return .streak

        default:

            if daysAgo % 13 == 0 {
                return .skip
            }

            if daysAgo % 17 == 0 {
                return .freeze
            }

            return .streak
        }
    }
}

#endif

