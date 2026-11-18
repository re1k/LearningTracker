import SwiftUI
import SwiftData

struct setTarget : View {
    
    //manage values inside UI views, pass it to viewModel
    @Environment(\.modelContext) private var modelContext
    
    @State var logViewModel: LogLearningViewModel?
    @Bindable var target: Target
    
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
                    Text("Set a New Goal")
                    .font(Fonts.buttonText)}
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        logViewModel?.setTarget()
                        dismiss()
                    } label: {
                            Image(systemName: "checkmark")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .glassEffect(
                                    .regular.tint(.orange).interactive(),
                                    in: Circle()
                                )
                        }
                        .buttonStyle(.plain)
                        .frame(width: 36, height: 36)
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
