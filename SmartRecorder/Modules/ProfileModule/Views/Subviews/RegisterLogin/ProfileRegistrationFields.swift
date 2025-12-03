//
//  ProfileRegistrationFields.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 03/12/2025.
//

import SwiftUI

struct RegistrationFields: View {
    
    @ObservedObject var viewModel: ProfileViewModel
    
    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
    }
    
    internal var body: some View {
        VStack(spacing: 16) {
            FloatingField(
                title: Texts.ProfilePage.FloatingFields.Nickname.title,
                text: $viewModel.registerForm.username,
                placeholder: Texts.ProfilePage.FloatingFields.Nickname.placeholder)
            FloatingField(
                title: Texts.ProfilePage.FloatingFields.Email.title,
                text: $viewModel.registerForm.email, isSecure: false,
                keyboard: .emailAddress,
                placeholder: Texts.ProfilePage.FloatingFields.Email.placeholder)
            FloatingField(
                title: Texts.ProfilePage.FloatingFields.Password.title,
                text: $viewModel.registerForm.password,
                isSecure: true,
                placeholder: Texts.ProfilePage.FloatingFields.Password.placeholder)
            FloatingField(
                title: Texts.ProfilePage.FloatingFields.PasswordConfirmation.title,
                text: $viewModel.registerForm.confirmPassword,
                isSecure: true,
                placeholder: Texts.ProfilePage.FloatingFields.PasswordConfirmation.placeholder)
        }
        .modifier(CardFieldsModifier())
    }
}

#Preview {
    RegistrationFields(viewModel: ProfileViewModel())
}
