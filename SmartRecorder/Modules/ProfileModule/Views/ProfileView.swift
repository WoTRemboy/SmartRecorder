import SwiftUI

struct ProfileView: View {
    
    @StateObject private var viewModel = ProfileViewModel()
    
    internal var body: some View {
        content
            .alert(Texts.ProfilePage.ErrorAlert.title,
                   isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { _ in viewModel.errorMessage = nil })) {
                Button(Texts.ProfilePage.ErrorAlert.ok, role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        
            .overlay(alignment: .top) {
                if let info = viewModel.infoMessage {
                    InfoToast(text: info) { viewModel.infoMessage = nil }
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 8)
                }
            }
            .safeAreaInset(edge: .bottom) {
                safeAreaInset
            }
            .background(Color.BackgroundColors.primary)
            .ignoresSafeArea(.keyboard)
    }
    
    private var content: some View {
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
    
    private var safeAreaInset: some View {
        VStack {
            AuthButton(isLoading: viewModel.isLoading, title: viewModel.mode.actionName) {
                Task {
                    await viewModel.submit()
                }
            }
            .disabled(viewModel.isLoading || !viewModel.canSubmit)
            
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
    ProfileView()
}

