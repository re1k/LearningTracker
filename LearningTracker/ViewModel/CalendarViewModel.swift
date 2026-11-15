import SwiftUI
import Observation

@Observable
class CalendarViewModel {
    
    //Can be read but not modfied
    private(set) var dailyLogs: [DailyLog] = [] //logs received from HomeView
    private(set) var logsByDay: [Date: DailyLog] = [:] //stores the indexed logs using their dates as keys, for faster search
  
    init(dailyLogs: [DailyLog]) {
        self.dailyLogs = dailyLogs
        prepareLogsDictionary()
    }
    
    // MARK: - Fill Dictionary
    private func prepareLogsDictionary() {
        logsByDay = Dictionary(
            dailyLogs.map {
                (
                    calendar.startOfDay(for: $0.dayDate),
                    $0
                )
            },
            uniquingKeysWith: { first, _ in first }
        )
    }
    
    //user's calendar settings
    private let calendar = Calendar.current
    
    // MARK: - Today's Log
    var todayLog: DailyLog? {
        getLog(for: Date())
    }
    //check if today has been logged
    var hasLoggedToday: Bool {
        todayLog != nil
    }
    
    //get the beginning of the current month the user started using the app in
    private var appStartDate: Date {
        UserDefaults.standard.object(
            forKey: "appStartDate"
        ) as? Date ?? Date()
    }
    
    
    // MARK: - Generate Week Dates
    func getCurrentWeekDates() -> [Date] {
        
        //checks whether an optional instance contains a wrapped value. If it does, the value is bound to (interval) variable
        //If the optional contains nil, the else branch executes
        guard let dateInterval = calendar.dateInterval(
            //search for a week in a year
            of: .weekOfYear,
            for: Date() //that has todays date in it
        ) else {
            return []
        } //returns optinal dateInterval, having (.start) be first day of current week and (.end) is last day of week
        
        //generates the array of week dates, by adding the days starting first of week, until creating the other 6 days
        return (0..<7).compactMap {
            //using CompactMap to remove any nil, as it retrun (Date?)
            calendar.date(
                //add a $num of days, to create the array of days from the start of week
                byAdding: .day,
                value: $0,
                to: dateInterval.start
            )
        }
    }
    
    // MARK: - Simple Logic
    
    //check if a day has a log
    func getLog(for date: Date) -> DailyLog? {
        //returns the DailyLog mapped to the given date
        logsByDay[calendar.startOfDay(for: date)]
    }
    //if day is today
    func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
    

    // MARK: - Generate Month Dates
    func getMonthDates(for month: Date) -> [Date?] {
        
        //get the date interval of the given month, For example, November 15 -> (Nov 1 - Dec 1)
        guard let interval = calendar.dateInterval(
            of: .month,
            for: month //the given date coming from calendarHistory
        ) else {
            return []
        }
        
        //get the total number of days in this month.
        let numberOfDays = calendar.range(
            of: .day,
            in: .month,
            for: month
        )!.count
        
        //find which weekday the first day of the month falls on.
        //calendar object uses the user current settings
        let firstWeekday = calendar.component(
            //extracts a specific component from a date here its the wekday number from the start interval
            .weekday, //weekday number ( 4 = Wed )
            from: interval.start //first day of the month
        )
        
        //calculate how many empty spaces we need, offset of 3 is 3 empty days
        //before day 1 so it aligns with the correct weekday column.
        //also accounts for the user's firstWeekday setting.
        let offsetFirstWeekDay = (
            firstWeekday - calendar.firstWeekday + 7
        ) % 7 //range ( 0 - 6 )
        
        //create empty spaces before the first day.
        let emptyDays = Array<Date?>( //date? allows us to use nil
            repeating: nil,
            count: offsetFirstWeekDay
        )
        
        //generate all actual dates belonging to this month.
        //starting from the first day of the month,
        let days = (0..<numberOfDays).compactMap {
            calendar.date(
                byAdding: .day,
                value: $0,
                to: interval.start
            )
        }
            .map {
                //casting each object to Date?, to match the embty days array so Swift can combine them
                Optional($0) }
        
        //combine the empty spaces with the actual dates, Complete calendar grid
        return emptyDays + days
    }
    
    // MARK: - generate monthes that has previous logs + the current month
    func getHistoryDates() -> [Date] {
        
            //beginning of the month the user started using the app
            // returns ex: November 1, 2026 at 00:00:00
            let startMonth = calendar.dateInterval(
                of: .month,
                for: appStartDate
            )!.start
            
            //beginning of the current month
            let currentMonth = calendar.dateInterval(
                of: .month,
                for: Date()
            )!.start
            
            //calculate the number of months between them
            let monthCount = calendar.dateComponents(
                [.month],
                from: startMonth,
                to: currentMonth
            ).month ?? 0
            
            //generate months from app start through current month, showing only monthes that has logs + current month
            return (0...monthCount).compactMap { index in
                calendar.date(
                    byAdding: .month,
                    value: index,
                    to: startMonth
                )
            }
        
        }
    
    
    // MARK: - Update Daily Logs
    func updateDailyLogs(_ logs: [DailyLog]) {

        dailyLogs = logs

        prepareLogsDictionary()
    }
    
}
