import SwiftUI
import SwiftData

struct AppRootView: View {

    @Environment(\.modelContext) private var modelContext

    @AppStorage("hasCompletedOnboarding")
    private var hasCompletedOnboarding = false

    var body: some View {

        Group {
            if hasCompletedOnboarding {
                Home()
            } else {
                Onboarding()
            }
        }
    }
}
