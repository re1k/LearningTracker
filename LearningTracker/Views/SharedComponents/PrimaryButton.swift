import SwiftUI

struct PrimaryButton: View {
    
    let text: String
    
    var isDisabled: Bool = false
    var isFreezeBtn: Bool = false
    var icon: String = ""
    let action: () -> Void

    var body: some View {

        Button(action: action) {

            Text(text)
                .font(Fonts.buttonText)
                .frame(maxWidth: .infinity)
                .frame(minHeight: Spacing.buttonFHeight)
        }
        .background(
                        isDisabled
                            ? Color.gray
                            : (isFreezeBtn ? Color.cyan : Color.orange)
                    )
        .foregroundColor(Color.white)
        .cornerRadius(.infinity)
        .frame(maxWidth: isFreezeBtn ? Spacing.buttonFreeze : Spacing.button)
        .disabled(isDisabled)
        .glassEffect()
    }
}



#Preview {
    PrimaryButton(text: "Hello", isFreezeBtn: true ,action: {})
}
