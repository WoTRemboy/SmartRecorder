import SwiftUI

struct ProfileRegisterLoginView: View {
    
    @ObservedObject var viewModel: ProfileViewModel
    
    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
    }
    
    internal var body: some View {
        VStack(spacing: 24) {
            Text(viewModel.mode.title)
                .font(Font.buttonTitle())
                .foregroundStyle(Color.LabelColors.primary)
                .padding(.bottom, 8)
                .id(viewModel.mode)
                .transition(.blurReplace)
            
            forms
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal)
        .animation(.easeInOut, value: viewModel.mode)
        .safeAreaInset(edge: .bottom) {
            bottomInset
        }
        .alert(Texts.ProfilePage.ErrorAlert.title,
               isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { _ in viewModel.errorMessage = nil })) {
                    Button(Texts.ProfilePage.ErrorAlert.ok, role: .cancel) { viewModel.errorMessage = nil }
                } message: {
                    Text(viewModel.errorMessage ?? "")
                }
    }
    
    private var forms: some View {
        Group {
            if viewModel.mode == .register {
                RegistrationFields(viewModel: viewModel)
                    .transition(.blurReplace)
            } else {
                LoginFields(viewModel: viewModel)
                    .transition(.blurReplace)
            }
        }
    }
    
    private var bottomInset: some View {
        VStack {
            AuthButton(isLoading: viewModel.isLoading, title: viewModel.mode.actionName) {
                Task {
                    await viewModel.submit()
                }
            }
            
            Button(action: { withAnimation(.easeInOut) { viewModel.toggleMode() } }) {
                Text(viewModel.mode.secondActionName)
                    .foregroundStyle(Color.LabelColors.purple)
                    .padding(.vertical, 8)
                    .id(viewModel.mode)
                    .transition(.blurReplace)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 24)
    }
}

#Preview {
    ProfileRegisterLoginView(viewModel: ProfileViewModel())
}

