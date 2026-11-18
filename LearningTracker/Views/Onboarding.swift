import SwiftUI
import SwiftData

// onborading page: taking first time (goal + duration)
struct OnBorading: View {
    
    //The Screen: Has State ownership and coordination, Creates the ViewModel
    //manage values inside UI views, pass it to viewModel
    @Environment(\.modelContext) private var modelContext
    
    @AppStorage("hasCompletedOnboarding")
    private var hasCompletedOnboarding = false
    
    //Create viewMidel This is my instance. I'm responsible for its lifetime
    @State private var viewModel: LogLearningViewModel?
    
    var body: some View {
        
           VStack(spacing: 0){
            
            Greetings()
            
            //MARK: - pass to the Set Goal componant
            if let viewModel {
                //ASSIGN WHEN NOT NULL
                setNewGoal(viewModel: viewModel)
            }
            
            Spacer(minLength: 0)
            
               VStack(spacing: Spacing.elementSpace){
                   Button {
                       guard let viewModel else { return }
                       //MARK: - set target
                       viewModel.setTarget()
                       // Navigate to the next screen
                       hasCompletedOnboarding = true
                   } label: {
                       
                       Text("Start Learning")
                           .font(Fonts.buttonText)
                           .foregroundStyle(.white)
                           .frame(width: 151 , height: 38)
                   }
                   
                   .buttonStyle(.glassProminent)
                   .tint(Color.orange) //native Liquid glass
                   .buttonBorderShape(.roundedRectangle(radius: .infinity))
                   
                   Text("You can edit your desire later")
                       .font(Fonts.statusText)
                   .foregroundColor(Color.gray)}
        }
        .padding( .horizontal, Spacing.pageMargine)
        //if no instance of the viewModel exists create it
        .task {
            if viewModel == nil {
                
                //just at start
                let target = Target(
                    goal: "",
                    duration: 7
                )
                
                //Create instance
                viewModel = LogLearningViewModel(
                    target: target, modelContext: modelContext
                )
            }
        }
    }
}
    
    struct Greetings: View {
        var body: some View{
            
            Image(systemName:"flame.fill").resizable().frame(maxWidth:30,maxHeight:40)
                .frame(maxWidth: .infinity).padding(.vertical, Spacing.sectionSpace)
                .foregroundColor(Color.orange)
            
            VStack(spacing: Spacing.subTitleSpace){
                
                Text("Hello Learner")
                    .font(Fonts.homeTitle).frame(maxWidth: .infinity, alignment: .leading)
                
                Text("This app will help you learn everyday!")
                    .font(Fonts.subtitle).frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(Color.gray)
                
            }.padding( .vertical, Spacing.sectionSpace)
        }
    }


#Preview {
    OnBorading()
}
