import SwiftUI
import SwiftData

struct editTarget : View {
    //manage values inside UI views, pass it to viewModel
    @Environment(\.modelContext) private var modelContext
    
    @State var logViewModel: LogLearningViewModel?
    @Bindable var target: Target

    //Popup regarding streak reset
    @State private var showingUpdateConfirmation = false
    //On done go ack home and close the page
    @Environment(\.dismiss) private var dismiss

    var body: some View{
        
        VStack(){

            //ASSIGN WHEN NOT NULL
            if let logViewModel {
                setNewGoal(viewModel: logViewModel)
            }
            
            
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
         .padding(.top, Spacing.buttonFHeight)
         .padding(.horizontal, 16)
         .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Learning Goal")
                    .font(Fonts.buttonText)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingUpdateConfirmation = true
                } label: {
                    Image(systemName: "checkmark")
                              .frame(width: 44, height: 44)
                      }
                .buttonStyle(.plain)
                .glassEffect(.regular.tint(.orange).interactive(), in: Circle())
                .alert(
                    "Update goal?",
                    isPresented: $showingUpdateConfirmation
                ) {
                    Button("Dismiss", role: .cancel) {
                        // Do nothing
                    }

                    Button("Update", role: .destructive) {
                        print("1. Before updating target")

                        logViewModel?.updateTarget()

                        print("2. Before resetting today's log")

                        logViewModel?.resetTodaysLog()

                        print("3. After resetting today's log")

                        dismiss()
                    }

                } message: {
                    Text("If you update now, your streak will start over.")
                }
            }
        }
        
        //if no instance of the viewModel exists create it
        .task {
            if logViewModel == nil {
                //Create instance
                logViewModel = LogLearningViewModel(
                    target: target,
                    modelContext: modelContext
                )
            }
        }
    }
}
