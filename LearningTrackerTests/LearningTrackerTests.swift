 import XCTest
import SwiftData
@testable import LearningTracker //the app

@MainActor
final class LearningTrackingTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    // MARK: - Setup

    override func setUpWithError() throws {
        let schema = Schema([
            Target.self,
            DailyLog.self
        ])

        let configuration = ModelConfiguration(
            isStoredInMemoryOnly: true
        )

        container = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )

        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        context = nil
        container = nil
    }

    // MARK: - Helpers

    private func createTarget(
        goal: String = "Learn Swift",
        duration: Int = 7
    ) -> Target {

        let target = Target(
            goal: goal,
            duration: duration
        )

        context.insert(target)

        return target
    }

    private func createViewModel(
        target: Target,
        date: Date = Date()
    ) -> LogLearningViewModel {

        let todayLog = DailyLog(
            dayDate: date,
            logStatus: .skip
        )

        context.insert(todayLog)

        return LogLearningViewModel(
            target: target,
            dailyLog: todayLog,
            allDailyLogs: [todayLog],
            modelContext: context
        )
    }

    private func logLearningDay(
        viewModel: LogLearningViewModel,
        date: Date
    ) {

        let log = DailyLog(
            dayDate: date,
            logStatus: .skip
        )

        viewModel.updateDailyLog(log)
        viewModel.allDailyLogs.append(log)

        viewModel.setStatus(status: .streak)
    }


    // MARK: - 1. Creating Goals

    func testCreateWeeklyMonthlyAndYearlyGoals() throws {

        let goalOptions: [(Int, Int)] = [
            (7, 2),
            (30, 8),
            (365, 96)
        ]

        for (duration, expectedFreezes) in goalOptions {

            let target = Target(
                goal: "Learn Swift",
                duration: duration
            )

            let viewModel = LogLearningViewModel(
                target: target,
                modelContext: context
            )

            viewModel.setTarget()

            XCTAssertEqual(target.duration, duration)

            XCTAssertEqual(
                target.freezeAmount,
                expectedFreezes,
                "Incorrect freeze allowance for \(duration)-day goal"
            )

            XCTAssertEqual(target.streakCounter, 0)
            XCTAssertEqual(target.freezeCounter, 0)
        }

        let savedTargets = try context.fetch(
            FetchDescriptor<Target>()
        )

        XCTAssertEqual(savedTargets.count, 3)
    }


    // MARK: - 2. Successfully Reaching Goals

    func testWeeklyMonthlyAndYearlyGoalsCanBeReached() {

        let durations = [7, 30, 365]

        for duration in durations {

            let target = createTarget(duration: duration)

            let startDate = Calendar.current.startOfDay(
                for: Date()
            )

            let viewModel = createViewModel(
                target: target,
                date: startDate
            )

            for day in 0..<duration {

                let date = Calendar.current.date(
                    byAdding: .day,
                    value: day,
                    to: startDate
                )!

                logLearningDay(
                    viewModel: viewModel,
                    date: date
                )
            }

            XCTAssertEqual(
                target.streakCounter,
                duration
            )

            XCTAssertEqual(
                viewModel.isTargetReached,
                true,
                "\(duration)-day goal should be reached"
            )
        }
    }


    // MARK: - 3. Goal Not Reached / Streak Reset

    func testLosingStreakResetsProgressAndMarksGoalUnsuccessful() {

        let target = createTarget(duration: 7)

        target.streakCounter = 4
        target.freezeCounter = 1

        // Last protected learning day was 33 hours ago.
        let lastLogDate = Date().addingTimeInterval(
            -(33 * 3600)
        )

        let lastLog = DailyLog(
            dayDate: lastLogDate,
            logStatus: .streak
        )

        context.insert(lastLog)

        let viewModel = LogLearningViewModel(
            target: target,
            dailyLog: nil,
            allDailyLogs: [lastLog],
            modelContext: context
        )

        viewModel.trackSkipped()

        XCTAssertEqual(
            target.streakCounter,
            0
        )

        XCTAssertEqual(
            target.freezeCounter,
            0
        )

        XCTAssertEqual(
            viewModel.isTargetReached,
            false
        )
    }


    // MARK: - 4. Streak Still Protected Within 32 Hours

    func testStreakDoesNotResetBefore32Hours() {

        let target = createTarget()

        target.streakCounter = 4
        target.freezeCounter = 1

        let lastLogDate = Date().addingTimeInterval(
            -(31 * 3600)
        )

        let lastLog = DailyLog(
            dayDate: lastLogDate,
            logStatus: .streak
        )

        context.insert(lastLog)

        let viewModel = LogLearningViewModel(
            target: target,
            dailyLog: nil,
            allDailyLogs: [lastLog],
            modelContext: context
        )

        viewModel.trackSkipped()

        XCTAssertEqual(target.streakCounter, 4)
        XCTAssertEqual(target.freezeCounter, 1)

        XCTAssertNil(viewModel.isTargetReached)
    }


    // MARK: - 5. Editing an Existing Goal

    func testEditingGoalResetsProgressAndUpdatesFreezeAllowance() {

        let target = createTarget(
            goal: "Learn Swift",
            duration: 7
        )

        target.streakCounter = 5
        target.freezeCounter = 1

        // User edits the existing goal.
        target.goal = "Learn SwiftUI"
        target.duration = 30

        let viewModel = LogLearningViewModel(
            target: target,
            modelContext: context
        )

        viewModel.updateTarget()

        XCTAssertEqual(target.goal, "Learn SwiftUI")
        XCTAssertEqual(target.duration, 30)

        XCTAssertEqual(target.freezeAmount, 8)

        XCTAssertEqual(target.streakCounter, 0)
        XCTAssertEqual(target.freezeCounter, 0)
    }


    // MARK: - 6. Starting a New Goal After Finishing

    func testStartingNewGoalResetsPreviousGoalResult() {

        let target = createTarget()

        target.streakCounter = 7

        let viewModel = LogLearningViewModel(
            target: target,
            modelContext: context
        )

        // Previous goal has been reached.
        viewModel.isTargetReached = true

        // User starts another goal using the same target.
        target.goal = "Learn UIKit"
        target.duration = 30

        viewModel.setTarget()

        XCTAssertEqual(target.goal, "Learn UIKit")
        XCTAssertEqual(target.duration, 30)

        XCTAssertEqual(target.streakCounter, 0)
        XCTAssertEqual(target.freezeCounter, 0)
        XCTAssertEqual(target.freezeAmount, 8)

        XCTAssertNil(viewModel.isTargetReached)
    }


    // MARK: - 7. Freeze Logging

    func testUsingFreezeIncreasesFreezeCounter() {

        let target = createTarget()

        let viewModel = createViewModel(
            target: target
        )

        viewModel.setStatus(status: .freeze)

        XCTAssertEqual(target.freezeCounter, 1)
        XCTAssertEqual(target.streakCounter, 0)

        XCTAssertEqual(
            viewModel.dailyLog?.logStatus,
            .freeze
        )
    }


    func testCannotUseMoreFreezesThanAllowed() {

        let target = createTarget()

        target.freezeCounter = target.freezeAmount

        let viewModel = createViewModel(
            target: target
        )

        viewModel.setStatus(status: .freeze)

        XCTAssertEqual(
            target.freezeCounter,
            target.freezeAmount
        )

        XCTAssertEqual(
            viewModel.dailyLog?.logStatus,
            .skip
        )
    }

    // MARK: - 8. Calendar Updates When Data Changes

    func testCalendarRefreshesWhenDailyLogsAreUpdated() {

        let target = createTarget()

        let firstDate = Calendar.current.startOfDay(
            for: Date()
        )

        let firstLog = DailyLog(
            dayDate: firstDate,
            logStatus: .streak
        )

        let calendarViewModel = CalendarViewModel(
            dailyLogs: [firstLog]
        )

        XCTAssertEqual(
            calendarViewModel.getLog(for: firstDate)?.logStatus,
            .streak
        )

        // A new day gets logged.
        let secondDate = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: firstDate
        )!

        let secondLog = DailyLog(
            dayDate: secondDate,
            logStatus: .freeze
        )

        calendarViewModel.updateDailyLogs([
            firstLog,
            secondLog
        ])

        XCTAssertEqual(
            calendarViewModel.dailyLogs.count,
            2
        )

        XCTAssertEqual(
            calendarViewModel.getLog(for: secondDate)?.logStatus,
            .freeze
        )
    }


    // MARK: - 9. Weekly Calendar

    func testWeeklyCalendarContainsSevenDays() {

        let target = createTarget()

        let date = Date()

        let calendarViewModel = CalendarViewModel(
            dailyLogs: []
        )

        let weekDates = calendarViewModel.getCurrentWeekDates(
            for: date
        )

        XCTAssertEqual(weekDates.count, 7)
    }


    // MARK: - 11. Home Card Counters

    func testHomeCountersReflectLearningAndFreezeLogs() {

        let target = createTarget()

        let startDate = Calendar.current.startOfDay(
            for: Date()
        )

        let viewModel = createViewModel(
            target: target,
            date: startDate
        )

        // First learning day.
        logLearningDay(
            viewModel: viewModel,
            date: startDate
        )

        // Second learning day.
        let secondDate = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: startDate
        )!

        logLearningDay(
            viewModel: viewModel,
            date: secondDate
        )

        // Third day uses a freeze.
        let thirdDate = Calendar.current.date(
            byAdding: .day,
            value: 2,
            to: startDate
        )!

        let freezeLog = DailyLog(
            dayDate: thirdDate,
            logStatus: .skip
        )

        viewModel.updateDailyLog(freezeLog)
        viewModel.allDailyLogs.append(freezeLog)

        viewModel.setStatus(status: .freeze)

        XCTAssertEqual(target.streakCounter, 2)
        XCTAssertEqual(target.freezeCounter, 1)

        // These are the values consumed by the Home cards.
        XCTAssertEqual(target.streakCounter, 2)
        XCTAssertEqual(target.freezeCounter, 1)
    }
}
