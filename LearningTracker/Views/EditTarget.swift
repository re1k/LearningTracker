import SwiftUI
import SwiftData

struct editTarget:View {
    //manage values inside UI views, pass it to viewModel
    @Environment(\.modelContext) private var modelContext
    
    @State private var viewModel: SetNewGoalViewModel?
    @Bindable var target: Target
    
    //Popup regarding streak reset
    @State private var showingUpdateConfirmation = false
    //On done go ack home and close the page
    @Environment(\.dismiss) private var dismiss


    var body: some View{
        
        VStack(){

            //ASSIGN WHEN NOT NULL
            if let viewModel {
                setNewGoal(viewModel: viewModel)
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
                        viewModel?.updateTarget()
                        //retrun home
                        dismiss()
                    }

                } message: {
                    Text("If you update now, your streak will start over.")
                }
            }
        }
        
        //if no instance of the viewModel exists create it
        .task {
            if viewModel == nil {
                //Create instance
                viewModel = SetNewGoalViewModel(
                    target: target,
                    modelContext: modelContext
                )
            }
        }
    }
}
