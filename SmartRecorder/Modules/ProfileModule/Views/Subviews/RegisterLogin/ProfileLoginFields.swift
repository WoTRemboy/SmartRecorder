//
//  ProfileLoginFields.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 03/12/2025.
//

import SwiftUI

struct LoginFields: View {
    
    @ObservedObject var viewModel: ProfileViewModel
    
    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
    }
    
    internal var body: some View {
        VStack(spacing: 16) {
            FloatingField(
                title: Texts.ProfilePage.FloatingFields.Email.title,
                text: $viewModel.login.email,
                keyboard: .emailAddress,
                placeholder: Texts.ProfilePage.FloatingFields.Email.placeholder)
            FloatingField(
                title: Texts.ProfilePage.FloatingFields.Password.title,
                text: $viewModel.login.password,
                isSecure: true,
                placeholder: Texts.ProfilePage.FloatingFields.Password.placeholder)
        }
        .modifier(CardFieldsModifier())
    }
}

#Preview {
    LoginFields(viewModel: ProfileViewModel())
}
