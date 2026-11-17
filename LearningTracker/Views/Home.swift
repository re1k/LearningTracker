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
                        }).padding(.horizontal, Spacing.pageMargine)

                        VStack(spacing: Spacing.elementSpace)
                        {
                            // MARK: - Week calendar row
                            CalendarWeekRow(viewModel: calendarViewModel,currentDay: currentDay)
                                .padding(.top, Spacing.elementSpace)
                            
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
                        }.padding(.horizontal, 14)
                        
                        // MARK: - Log Controls / Target Mark Result
                        if let logViewModel {

                            //created in here locally then passed
                            if let isReached = logViewModel.isTargetReached {

                                TargetMarked(logViewModel: logViewModel, target: target, isReached: isReached).padding(.top, 64)

                            } else {
                                LogControlButtons(
                                    viewModel: logViewModel,
                                    hasLoggedToday: calendarViewModel.hasLoggedToday
                                ).padding(.top, 48)
                            }
                        }

                    } else {
                        Text("No learning target found.")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
                        allDailyLogs: todayLog == nil //send todays log to append it
                                ? dailyLogs + [dailyLog]
                                : dailyLogs,
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

                // Update today's date when the user returns to the app,
                // in case the device date changed while the app was in the background.
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
        
        VStack(spacing: 48){
            // MARK: - Log Streak
            Button {
                viewModel.setStatus(status: LogStatus.streak)
            } label: {
                
                Text("Log as Learned")
                    .font(Fonts.buttonText)
                    .foregroundStyle(hasLoggedToday ? .gray : .white)
                    .frame(width: 272, height: 272)
            }
            .buttonStyle(.glassProminent) //native Liquid glass
            .buttonBorderShape(.circle)
            .tint(hasLoggedToday ? .clear : .orange)
            .buttonStyle(.glass)
            .tint(Color.orange)
            .disabled(hasLoggedToday)
            
            VStack(spacing: Spacing.pageMargine) {
                // MARK: - Log Freeze
                Button {
                    viewModel.setStatus(status: LogStatus.freeze)
                } label: {
                    
                    Text("Freeze for a day")
                        .font(Fonts.buttonText)
                        .frame(width:  268 , height: 38 )
                        .foregroundStyle(hasLoggedToday ? .gray : .white)
                }
                .buttonStyle(.glassProminent) //native Liquid glass
                .buttonBorderShape(.roundedRectangle(radius: .infinity))
                .tint(hasLoggedToday ? .clear : .cyan)
                .disabled(hasLoggedToday || viewModel.hasUsedAllFreezes)
                
                // MARK: - Freeze Info Dynamic (Change)
                Text("\(viewModel.target.freezeCounter) out of \(viewModel.target.freezeAmount) Freezes used")
                    .font(Fonts.body)
                    .foregroundColor(Color.gray)
            }
        }
        
    }
}


 struct ActivityHeader: View {
     
        var onEdit: () -> Void
        var onCalander: () -> Void

        var body: some View{
            
            VStack(){
                HStack(spacing: 42){
                    Text("Activity")
                        .font(Fonts.homeTitle).frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 12){
                        
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
                 .font(.system(size: 20, weight: .medium))
                 .frame(maxWidth: 44, maxHeight: 44)
        }
        .buttonStyle(.glass) //native liquid glass
        .frame(maxWidth: 44, maxHeight: 44)
        .clipShape(Circle())
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
            }.frame(width: 180, height: 102)
            .glassEffect(
                .regular.tint(.black.opacity(0.26)),
                in: cardShape
            )
        }
}

struct TargetMarked: View {
    
    let logViewModel: LogLearningViewModel
    let target: Target
    
    @State private var showSetNewGoal = false
    
    let isReached: Bool
    var iconName: String { isReached ?"hands.clap.fill": "xmark.seal"}
    var title: String { isReached ? "Well done!" : "You didn't reach your goal this time." }
    var subTitle: String { isReached ? "Ready for your next goal?" : "Want to set another goal?"
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
                .foregroundStyle(.primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
            .buttonStyle(.glassProminent) //native Liquid glass
            .buttonBorderShape(.roundedRectangle(radius: .infinity))
            .tint(Color.orange)
            .navigationDestination(isPresented: $showSetNewGoal) {
                // new goal screen
                setTarget(logViewModel: logViewModel,target: target)
            }
        }
    }
}
