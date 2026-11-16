import Foundation
import SwiftUI
import UIKit
import SwiftData

// My data an be observed changes can be tracked update views that read them.
// also in here any var that toggles to true or false to show or hide, in here can  be managed!
@Observable
final class LogLearningViewModel {
    
    //Passed by the Parent View (Hosting screen)
    private let modelContext: ModelContext
    
    var target: Target
    var dailyLog: DailyLog?
    var allDailyLogs: [DailyLog] = [] //added for tracking streak
    var isTargetReached: Bool? = nil // default meaning still in progress

   
    // MARK: - Onboarding initializer
     init(target: Target, modelContext: ModelContext) {
         self.target = target
         self.dailyLog = nil
         self.modelContext = modelContext
     }

    // MARK: - Home initializer
    init(target: Target,dailyLog: DailyLog, allDailyLogs: [DailyLog], modelContext: ModelContext) {
            self.target = target
            self.dailyLog = dailyLog
            self.allDailyLogs = allDailyLogs
            self.modelContext = modelContext
        }

    // MARK: - computed properties
    var hasUsedAllFreezes: Bool {
        target.freezeCounter >= target.freezeAmount
    }
    
    // MARK: - Target managment

    private func UpdatefreezeAmount(duration: DurationOptions.RawValue){
        switch duration {
                case 7:
            target.freezeAmount = 2
                case 30:
            target.freezeAmount = 8
                case 365:
            target.freezeAmount = 96
                default:
            target.freezeAmount = 0
                }
    }
    
    func setTarget() {
        print("Goal:", target.goal)
        print("Duration:", target.duration)
        
        // Configure the new goal
        UpdatefreezeAmount(duration: target.duration)
        
        // Reset progress
        target.streakCounter = 0
        target.freezeCounter = 0
        
        // Reset previous goal result
        isTargetReached = nil
        
        modelContext.insert(target)

        do {
            try modelContext.save()
            
            //DEBUG
            print("Target saved",target.goal )
            print("Target freeze",target.freezeCounter)
            print("Target streak",target.streakCounter )
            print("Freeze allowance:", target.freezeAmount)
            let descriptor = FetchDescriptor<Target>()
            let savedTargets = try modelContext.fetch(descriptor)
            print("Targets in database:", savedTargets.count)
            
        } catch {
            print("Save failed:", error)
        }
    }
    
    func updateTarget() {

        print("Updating goal:", target.goal)
        print("New duration:", target.duration)

        // Recalculate freeze allowance
        UpdatefreezeAmount(duration: target.duration)

        // Reset progress
        target.streakCounter = 0
        target.freezeCounter = 0

        do {
            try modelContext.save()

            print("Target updated successfully!")
            print("Goal:", target.goal)
            print("Duration:", target.duration)
            print("Freeze allowance:", target.freezeAmount)

        } catch {
            print("Update failed:", error)
        }
    }
    
    
    // MARK: - Daily Logging

    //Assigns the logging status to the day
    func setStatus(status: LogStatus) {

        // Make sure a daily log exists
            guard let dailyLog else {
                print("No daily log available")
                return
            }
    
        // Don't count the same day twice
        guard dailyLog.logStatus == .skip else {
               return
           }

        switch status {

        case .streak:
            target.streakCounter += 1

        case .freeze:
            guard target.freezeCounter < target.freezeAmount else {
                print("No freezes remaining")
                return
            }
            target.freezeCounter += 1

        case .skip:
            return
        }

        dailyLog.logStatus = status
        
        print("--Log timestamp:--", dailyLog.dayDate)
        print("--Current timestamp:--", Date())

        modelContext.insert(dailyLog)

        do {
            try modelContext.save()
            
            // Check whether the target has been reached
            markReached()
            
        } catch {
            print("Logging failed:", error)
        }
    }
    
    func resetTodaysLog() {
    
        //if value exists
        if let dailyLog {
                modelContext.delete(dailyLog)
            }

        dailyLog = DailyLog(
            dayDate: Calendar.current.startOfDay(for: Date()),
            logStatus: .skip
        )

        do {
            try modelContext.save()
            print("Today's log deleted successfully!")
        } catch {
            print("Reset failed:", error)
        }
    }
    
    func updateDailyLog(_ log: DailyLog) {
        dailyLog = log
    }
    
    // MARK: - Streak Tracking
    
    private func getLastProtectedLog() -> DailyLog? {

        var latestLog: DailyLog?
        //search for days logged (freeze/streak), finds the max time between them
        for log in allDailyLogs {

            guard log.logStatus == .streak ||
                  log.logStatus == .freeze else {
                continue
            }

            if let currentLatest = latestLog {

                if log.dayDate > currentLatest.dayDate {
                    latestLog = log
                }

            } else {
                latestLog = log
            }
        }
        //returns the dailylog with the latest date (last day logged)
        return latestLog
    }
    
    
   // starts tracking if there is (a skipped day + 8 hours) from the last logged thing ( either frees or streak )
    func trackSkipped() {
        
        guard let lastProtectedLog = getLastProtectedLog() else {
                return
            }
        
        // time passed from last loged day till today
        let hoursPassed = Date().timeIntervalSince(
                lastProtectedLog.dayDate
            ) / 3600
        
        //the user's streak is lost and the goal is unsuccessful.
        if hoursPassed >= 32 {
            
            target.streakCounter = 0
            markUnreached()

            //saves the restet to swiftData
            do {
                try modelContext.save()
            } catch {
                print("Streak reset failed:", error)
            }
        }
    }
    
    // MARK: - Target Marked Result

    // Checks whether the user has achieved the required consecutive learning days.
    private func markReached() {
        guard isTargetReached == nil else { return }

        guard target.streakCounter >= target.duration else {
            return
        }

        isTargetReached = true
        print("Goal reached!")
    }

    // Called when the user loses their streak after exceeding the 32-hour limit, If the streak is lost without protection, the goal is marked as unsuccessful.
    private func markUnreached() {
        guard isTargetReached == nil else { return }

        isTargetReached = false
        print("Goal not reached!")
    }
}
