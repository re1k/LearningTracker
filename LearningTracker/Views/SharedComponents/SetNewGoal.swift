import SwiftUI


struct setNewGoal : View {
    //(Bindable) create bindings to the ViewModel's properties using
    //I can connect UI controls directly to this object's properties
    
    //(Binding) What it means: You don't own the value. Someone else owns it, and you receive a connection to it. "Give me access to modify your value.", so in here the parent screen would have binded
    
    //and to decide that see who need to entrate with the data
    @Bindable var viewModel: LogLearningViewModel
    
    var body: some View{
        
        VStack(spacing:Spacing.elementSpace){
            
            // MARK: - Goal
            Text("I want to learn")
                .font(Fonts.subtitle)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            TextField("\(viewModel.target.goal)", text: $viewModel.target.goal)
                .foregroundColor(Color.primary)
            Rectangle().fill(Color.gray).frame(height: 0.3)
        }.padding(.bottom, Spacing.sectionSpace)
        
        
        // MARK: - Duration Chips
        VStack(spacing: Spacing.elementSpace) {

            Text("I want to learn in it in a")
                .font(Fonts.subtitle)
                .frame(maxWidth: .infinity, alignment: .leading)

            GlassEffectContainer(spacing: 8) {

                HStack(spacing: Spacing.elementSpace) {
                    ForEach(DurationOptions.allCases, id: \.self) { option in

                        let isSelected = viewModel.target.duration == option.rawValue

                         Button {
                             //Pass selected option value
                             viewModel.target.duration = option.rawValue
                         }  label: {

                            Text(option.title)
                                .font(Fonts.buttonText)
                                .padding(.horizontal, 10)
                                .padding(.vertical,7)
                                .foregroundColor(isSelected ? .white : .secondary)

                        }
                         .buttonStyle(.glassProminent)
                        .tint(
                            isSelected ? Color.orange : Color.gray.opacity(0.15)
                        )
                        .cornerRadius(999)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        
    }
}



