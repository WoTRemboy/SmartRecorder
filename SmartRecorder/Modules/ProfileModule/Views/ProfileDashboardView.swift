//
//  ProfileDashboardView.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 13/11/2025.
//

import SwiftUI

struct ProfileDashboardView: View {
    
    @ObservedObject private var viewModel: ProfileViewModel
    
    @State private var isShowingLogoutAlert: Bool = false
    @State private var isShowingClearCacheDialog: Bool = false
    
    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
    }
    
    internal var body: some View {
        VStack(spacing: 32) {
            EmailCardView(email: viewModel.email)
                .frame(maxHeight: .infinity, alignment: .center)
                .padding([.vertical, .horizontal], 16)
            
            statsContent
        }
        .padding(.horizontal)
        .padding(.bottom, 24)
        
        .navigationTitle(Texts.ProfilePage.User.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                logoutButton
            }
        }
        .frame(maxHeight: .infinity)
        .background(Color.BackgroundColors.primary)
        
        .safeAreaInset(edge: .bottom) {
            safeAreaInset
        }
        .task {
            viewModel.dashboardAppeared()
        }
    }
    
    private var statsContent: some View {
        HStack(alignment: .top, spacing: 40) {
            StatBlockView(title: Texts.ProfilePage.Dashboard.Stats.meetings, value: viewModel.value(forKeys: ["meetings", "meetingsCount"]))
            StatBlockView(title: Texts.ProfilePage.Dashboard.Stats.minutes, value: viewModel.value(forKeys: ["minutes", "minutesInMeetings"]))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
    
    private var safeAreaInset: some View {
        VStack(spacing: 26) {
            Text(viewModel.memoryUsageAttributed())
                .foregroundColor(Color.LabelColors.primary)
                .contentTransition(.numericText())
                .animation(.easeInOut, value: viewModel.audioCacheBytes)
            
            Button {
                isShowingClearCacheDialog.toggle()
            } label: {
                Text(Texts.ProfilePage.Dashboard.Cache.title)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .buttonStyle(.plain)
                    .cornerRadius(12)
            }
            .buttonStyle(.glassProminent)
            .tint(Color.SupportColors.blue)
            .confirmationDialog(Texts.ProfilePage.Dashboard.Cache.confirm, isPresented: $isShowingClearCacheDialog, titleVisibility: .visible) {
                Button(Texts.ProfilePage.Dashboard.Cache.action, role: .destructive) {
                    viewModel.clearCacheTapped()
                }
                Button(Texts.ProfilePage.Dashboard.Cache.cancel, role: .cancel) {}
            }
            .frame(height: 50)
        }
        .padding(.horizontal)
        .padding(.bottom, 36)
    }
    
    private var logoutButton: some View {
        Button(role: .none) {
            isShowingLogoutAlert.toggle()
        } label: {
            Text(Texts.ProfilePage.Dashboard.Logout.title)
        }
        .tint(Color.SupportColors.red)
        .confirmationDialog(Texts.ProfilePage.Dashboard.Logout.confirm, isPresented: $isShowingLogoutAlert, titleVisibility: .visible) {
            Button(Texts.ProfilePage.Dashboard.Logout.action, role: .destructive) {
                viewModel.logoutTapped()
            }
            Button(Texts.ProfilePage.Dashboard.Logout.cancel, role: .cancel) {}
        }
    }
}

#Preview {
    NavigationStack {
        ProfileDashboardView(viewModel: ProfileViewModel())
    }
}
