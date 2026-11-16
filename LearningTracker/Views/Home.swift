import SwiftUI
import SwiftData

struct Home: View {
    
    @Environment(\.modelContext) private var modelContext
    //to know the current lifecycle state of app (active or running in the background)
    @Environment(\.scenePhase) private var scenePhase

    
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

                        // MARK: - Log Controls / Target Mark Result
                        if let logViewModel {

                            //created in here locally then passed
                            if let isReached = logViewModel.isTargetReached {

                                TargetMarked(logViewModel: logViewModel,isReached: isReached)

                            } else {

                                LogControlButtons(
                                    viewModel: logViewModel,
                                    hasLoggedToday: calendarViewModel.hasLoggedToday
                                )
                            }
                            
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
                        editTarget(logViewModel: logViewModel,target: target)
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
                //update LogViewModel for tracking streak
                logViewModel?.allDailyLogs = newLogs

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
            //Recheck the user's streak whenever they return to the app, whether from the Home Screen or App Switcher.
            .onChange(of: scenePhase) { _, newPhase in
                //if user enter the app update streak status for simpler comupation rather than timer
                guard newPhase == .active else { return }

                logViewModel?.trackSkipped()
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

                Text("Log as Learned")
                       .font(Fonts.cardText)
                       .foregroundStyle(hasLoggedToday ? .gray : .white)
                    .frame(width: 272, height: 272)
        }
        .buttonStyle(.glassProminent) //native Liquid glass
        .buttonBorderShape(.circle)
        .tint(Color.orange)
        .disabled(hasLoggedToday)
        .padding(.bottom, Spacing.sectionSpace)
        
        // MARK: - Log Freeze
        Button {
            viewModel.setStatus(status: LogStatus.freeze)
        } label: {

                Text("Freeze for a day")
                       .font(Fonts.buttonText)
                       .foregroundStyle(hasLoggedToday ? .gray : .white)
                       .frame(width:  Spacing.buttonFreeze, height: Spacing.buttonFHeight)
        }
        .buttonStyle(.glassProminent) //native Liquid glass
        .buttonBorderShape(.roundedRectangle(radius: .infinity))
        .tint(Color.cyan)
        .disabled(hasLoggedToday || viewModel.hasUsedAllFreezes)
        
        // MARK: - Freeze Info Dynamic (Change)
        Text("\(viewModel.target.freezeCounter) out of \(viewModel.target.freezeAmount) Freezes used")
            .font(Fonts.cardText)
            .foregroundColor(Color.gray)
    }
}


 struct ActivityHeader: View {
        var onEdit: () -> Void
        var onCalander: () -> Void
        var goalTitle: String

        var body: some View{
            
            HStack(spacing: 42){
                Text("Activity")
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


struct TopButton: View {
    
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
        .buttonStyle(.glass) //native liquid glass
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
    private let cardShape = RoundedRectangle(
            cornerRadius: 34,
            style: .continuous)
    
    private var displayDay: String {
            number == 1 ? "day" : "days"
        }
    var body: some View {

            VStack(spacing: 4) {

                Image(systemName: logType)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 24)
                    .foregroundColor(tint)

                Text("\(number) \(displayDay)")
                    .font(Fonts.cardText)

                Text(title)
                    .font(Fonts.body)
            }.frame(width: 177, height: 102)
            .background {
                cardShape
                    .fill(Color(red: 26/255, green: 26/255, blue: 26/255).opacity(0.30))
            }
            .glassEffect(
                .regular,
                in: cardShape
            )
        }
}

struct TargetMarked: View {
    
    let logViewModel: LogLearningViewModel
    @State private var showSetNewGoal = false
    
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
            }.padding(.bottom , 64 )
            
            
            // MARK: - Set New Goal
            Button {
                showSetNewGoal = true
            } label: {
                
                HStack(spacing: 4) {
                    
                    Image(systemName: "pencil.and.outline")
                        .font(Fonts.buttonText)
                    
                    Text("Set a goal")
                        .font(Fonts.buttonText)
                }
                .buttonStyle(.glassProminent) //native Liquid glass
                .buttonBorderShape(.roundedRectangle(radius: .infinity))
                .tint(Color.orange)
                .navigationDestination(isPresented: $showSetNewGoal) {
                    // new goal screen
                    setNewGoal(viewModel: logViewModel)
                }
            }
        }
    }
}
