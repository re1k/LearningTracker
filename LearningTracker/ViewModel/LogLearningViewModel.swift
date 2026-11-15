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
    
    var dailyLog: DailyLog
    var target: Target
    var allDailyLogs: [DailyLog] //added for tracking streak
    var hasUsedAllFreezes: Bool {
        target.freezeCounter >= target.freezeAmount
    }

    init(target: Target,dailyLog: DailyLog, allDailyLogs: [DailyLog], modelContext: ModelContext) {
            self.target = target
            self.dailyLog = dailyLog
            self.allDailyLogs = allDailyLogs
            self.modelContext = modelContext
        }

    // Assigns the logging status to the day
    func setStatus(status: LogStatus) {

        // Don't count the same day twice
        if dailyLog.logStatus != .skip {
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
        modelContext.insert(dailyLog)

        do {
            try modelContext.save()
        } catch {
            print("Logging failed:", error)
        }
    }
    
    func updateDailyLog(_ log: DailyLog) {
        dailyLog = log
    }
    
    
    private func getLastProtectedLog() -> DailyLog? {
        allDailyLogs
            //filters days logged (freeze/streak), finds the max time between them
            .filter {
                $0.logStatus == .streak || $0.logStatus == .freeze
            }
            //returns the dailylog with the latest date (last day loggeds)
            .max {
                $0.dayDate < $1.dayDate
            }
    }
    
   // starts tracking if there is (a skipped day + 8 hours) from the last logged thing ( either frees or streak )
    func trackSkipped(target: Target) {
        
        guard let lastProtectedLog = getLastProtectedLog() else {
                return
            }
        
        //time passed from last loged day till today
        let hoursPassed = Date().timeIntervalSince(
                lastProtectedLog.dayDate
            ) / 3600
        
        //reset streak
        if hoursPassed >= 32 {
            target.streakCounter = 0
            
            //saves the restet to swiftData
            do {
                try modelContext.save()
            } catch {
                print("Streak reset failed:", error)
            }
        }
        
        
    }

    // func that takes the target duration log status,
    //check if goal reached
    private func markReached(target: Target) {
    }
    
    //check if goal unreached
    private func markUnreached(target: Target) {
    }

}
