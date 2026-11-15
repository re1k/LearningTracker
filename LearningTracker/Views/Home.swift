import SwiftUI
import SwiftData

struct Home: View {
    
    @Environment(\.modelContext) private var modelContext
    
    //Get (Current Target + the logs for calander row) Data From already saved data in the ModelContext
    @Query private var targets: [Target] //it return collection
    
    //managed by SwiftData
    @Query private var dailyLogs: [DailyLog]
    //managed by th viewModel
    @State private var calendarViewModel = CalendarViewModel(dailyLogs: [])

    //Top Buttons Navigation
    @State private var showEditTarget = false
    @State private var showCalanderTarget = false

    @State private var logViewModel: LogLearningViewModel?
    //Detect when a new calendar day begins, Detect the day has changed
    @State private var currentDay = Calendar.current.startOfDay(for: Date())
    
        var body: some View {

            NavigationStack {
                VStack(spacing: Spacing.subTitleSpace) {
                    // fetch the target first make sure its not nulll beofre ctearing views
                    if let target = targets.first {

                        // MARK: - Header
                        ActivityHeader(onEdit: {
                            showEditTarget = true
                        }, onCalander: {
                            showCalanderTarget = true
                        } ,
                        goalTitle: target.goal)

                        // MARK: - Week calendar row
                        CalendarWeekRow(viewModel: calendarViewModel)
                            .padding(.top, Spacing.pageMargine)

                        // MARK: - Log streak/Freeze Cards
                        HStack(spacing: 12) {

                            LogLearningCards(
                                logType: "flame.fill",
                                number: target.streakCounter,
                                title: "Learned",
                                tint: .orange
                            )

                            LogLearningCards(
                                logType: "snowflake",
                                number: target.freezeCounter,
                                title: "Freezed",
                                tint: .cyan
                            )
                        }
                        .padding()

                        // MARK: - Log Controls
                        if let logViewModel {
                            LogControlButtons(viewModel: logViewModel, hasLoggedToday: calendarViewModel.hasLoggedToday)
                        }

                    } else {
                        Text("No learning target found.")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.vertical, Spacing.sectionSpace)
                .padding(.horizontal, Spacing.pageMargine)
                // MARK: - Edit Screen
                .navigationDestination(isPresented: $showEditTarget) {
                    if let target = targets.first {
                        editTarget(target: target)
                    }
                }
                // MARK: - Calendar Screen
                .navigationDestination(isPresented: $showCalanderTarget) {
                    CalendarHistory(viewModel: calendarViewModel)
                }
                .task {
                    // Synchronize calendar data
                    calendarViewModel.updateDailyLogs(dailyLogs)

                    // Existing LogLearningViewModel initialization
                    print("Targets fetched: \(targets.count)")
                    
                    //debug
                    print("Targets fetched: \(targets.count)")
                    
                    //if no instance of the viewModel exists create it
                    guard logViewModel == nil,
                          let target = targets.first else { return }
                    let todayLog = dailyLogs.first {
                        Calendar.current.isDateInToday($0.dayDate)
                    }
                    let dailyLog = todayLog ?? DailyLog(
                        dayDate: Date(),
                        logStatus: LogStatus.skip
                    )

                    logViewModel = LogLearningViewModel(
                        target: target,
                        dailyLog: dailyLog,
                        allDailyLogs: dailyLogs,
                        modelContext: modelContext
                    )
                }
                
            }
            //whenever SwiftData changes, update the dailyLogs in the ViewModel
            .onChange(of: dailyLogs) { _, newLogs in
                calendarViewModel.updateDailyLogs(newLogs)
            }
            //when a new day begins, if log exist add it to the dailylog array if not create and mark skipped
            .onChange(of: currentDay) { _, newDay in

                let todayLog = calendarViewModel.getLog(for: newDay)

                let dailyLog = todayLog ?? DailyLog(
                    dayDate: newDay,
                    logStatus: .skip
                )
                logViewModel?.updateDailyLog(dailyLog)
            }
            //listen for iOS telling the calendar day has changed. When it happens, update currentDay at midnight
            .onReceive(
                NotificationCenter.default.publisher(
                    for: .NSCalendarDayChanged
                )
            ) { _ in
                currentDay = Calendar.current.startOfDay(for: Date())
            }
        }
    }



struct LogControlButtons: View {
    
    //and to decide that see who need to entrate with the data
    @Bindable var viewModel: LogLearningViewModel
    let hasLoggedToday: Bool
 
    var body: some View {
        // MARK: - Log Streak
        Button {
            viewModel.setStatus(status: LogStatus.streak)
        } label: {

            ZStack {

                Circle()
                    .fill( hasLoggedToday ? Color.gray : Color.orange)
                    .frame(width: 272, height: 272)

                Text("Log as Learned")
                    .font(Fonts.cardText)
                    .foregroundColor(.white)
            }
        }
        .glassEffect()
        .disabled(hasLoggedToday)
        .padding(.bottom, Spacing.sectionSpace)

    
    
        // MARK: - Log Freeze
        PrimaryButton(
            text: "Freeze for a day",
            isDisabled: hasLoggedToday,
            isFreezeBtn: true
        ) {
            viewModel.setStatus(status: LogStatus.freeze)
        }

        // MARK: - Freeze Info Dynamic (Change)
        Text("\(viewModel.target.freezeCounter) out of \(viewModel.target.freezeAmount) Freezes used")
            .font(Fonts.cardText)
            .foregroundColor(Color.gray)
    }
}

 
    struct  ActivityHeader: View {
        var onEdit: () -> Void
        var onCalander: () -> Void
        var goalTitle: String

        var body: some View{
            
            HStack(spacing: 42){
                Text("Goal: \(goalTitle)")
                    .font(Fonts.homeTitle).frame(maxWidth: .infinity, alignment: .leading)
        
                HStack(spacing: 4){
                    
                    //MARK: - navigate to calander later
                    TopButton(action: onCalander ,IconName: "calendar")
                    
                    //MARK: - navigate to Edit later
                    TopButton(action: onEdit, IconName: "pencil.and.outline")
                }
            }
            //MARK: -  Date of today update
            Text("\(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))")
                .font(Fonts.subtitle).frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(Color.gray)
        }
    }




struct TopButton: View{
    
    //no args no retrun func
    var action: () -> Void
    let IconName: String
    
    var body: some View{
        
        // MARK: - navigate to calander
        
        //exec the func when tapped
        Button (action: action)
         {
            Image(systemName: IconName)
                 .resizable()
                 .scaledToFit()
                .frame(maxWidth: 35, maxHeight: 36)
        }
        .buttonStyle(.glass)
        .cornerRadius(.infinity)
        .frame(maxWidth: 44, maxHeight: 44)
    }

    
}


struct LogLearningCards: View {
    let logType: String
    //Changes
    let number: Int
    let title: String
    let tint: Color

    var body: some View {

        ZStack {

            RoundedRectangle(cornerRadius: 34)
                .fill(.clear)
                .frame(width: 177, height: 102)
                .glassEffect()

            VStack(spacing: 4) {

                Image(systemName: logType)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 24)
                    .foregroundColor(tint)

                Text("\(number) Days")
                    .font(Fonts.cardText)

                Text(title)
                    .font(Fonts.body)
            }
        }
    }
}



struct TargetMarked: View {
    
    let isReached: Bool
    var iconName: String { isReached ?"hands.clap.fill": "xmark.seal"}
    var title: String { isReached ? "Well done!" : "You didn't reach your goal this time." }
    var subTitle: String { isReached ? "Ready for your next  let title goal?" : "Want to set another goal?"
    }
        
    var body: some View {
                
        VStack(spacing: 19 ) {
            
            Image(systemName: iconName )
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(Color.orange)
            
            VStack(spacing: Spacing.subTitleSpace){
               
                Text(title)
                .font(Fonts.buttonText)
                
                Text(subTitle)
                    .font(Fonts.body).foregroundColor(Color.gray)
            }
        }.padding(.vertical, 65)
        
    }
}





// TEST ONLY ONLY
import Foundation
struct DummyDailyLogs {

    static let logs: [DailyLog] = {

        let calendar = Calendar.current

        let today = calendar.startOfDay(for: Date())

        // Generate dates relative to today.
        func date(daysAgo: Int) -> Date {
            calendar.date(
                byAdding: .day,
                value: -daysAgo,
                to: today
            )!
        }

        return [

            // Learned days
            DailyLog(dayDate: date(daysAgo: 0), logStatus: .streak),
            DailyLog(dayDate: date(daysAgo: 1), logStatus: .streak),
            DailyLog(dayDate: date(daysAgo: 3), logStatus: .streak),
            DailyLog(dayDate: date(daysAgo: 5), logStatus: .streak),
            DailyLog(dayDate: date(daysAgo: 8), logStatus: .streak),
            DailyLog(dayDate: date(daysAgo: 10), logStatus: .streak),

            // Freeze days
            DailyLog(dayDate: date(daysAgo: 2), logStatus: .freeze),
            DailyLog(dayDate: date(daysAgo: 6), logStatus: .freeze),
            DailyLog(dayDate: date(daysAgo: 12), logStatus: .freeze),

            // Skipped days (no tint)
            DailyLog(dayDate: date(daysAgo: 4), logStatus: .skip),
            DailyLog(dayDate: date(daysAgo: 7), logStatus: .skip),
            DailyLog(dayDate: date(daysAgo: 9), logStatus: .skip)
        ]

    }()
}

#Preview {
    
    let viewModel = CalendarViewModel(
           dailyLogs: DummyDailyLogs.logs
       )
    
        // Home(CalendarViewModel: viewModel)
}
