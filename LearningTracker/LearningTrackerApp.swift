import SwiftUI
import SwiftData

@main
struct MyApp: App {
    
    
    //for rounting to home
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    //on app init
    init() {
        let defaults = UserDefaults.standard

        //for calendar history, set to todays date, if not exists opening the app for the first time
        if defaults.object(forKey: "appStartDate") == nil {
            defaults.set(Date(), forKey: "appStartDate")
        }
     }
    
    var body: some Scene {
        WindowGroup {
            
            //Routing Screens
            if hasCompletedOnboarding
            { Home() }
            else
            { OnBorading() }
            
                }
        //singleton
        .modelContainer(for: [
                  Target.self,
                  DailyLog.self
        ]
        )
    }
}
