//
//  ProfileView.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 13/11/2025.
//
import SwiftUI

struct ProfileView: View {
    
    @EnvironmentObject private var viewModel: ProfileViewModel
    
    internal var body: some View {
        content
            .background(Color.BackgroundColors.primary)
            .ignoresSafeArea(.keyboard)
    }
    
    private var content: some View {
        ZStack {
            if viewModel.isAuthorized {
                ProfileDashboardView(viewModel: viewModel)
                    .transition(.blurReplace)
            } else {
                ProfileRegisterLoginView(viewModel: viewModel)
                    .transition(.blurReplace)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.isAuthorized)
    }
}

#Preview {
    ProfileView()
        .environmentObject(ProfileViewModel())
}

