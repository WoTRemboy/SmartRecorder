//
//  ContentView.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 09/11/2025.
//

import SwiftUI

/// The main content view of the app, responsible for setting up tab navigation and injecting view models.
struct ContentView: View {
    
    // MARK: - Properties
    
    /// Tab router to manage selected tab state across the app.
    @StateObject private var appRouter = AppRouter()
    @State private var search: String = ""
    
    private func bindingForTab(_ tab: AppRouter.Tab) -> Binding<[AppRouter.Route]> {
        Binding(
            get: { appRouter.navigationPaths[tab] ?? [] },
            set: { appRouter.navigationPaths[tab] = $0 }
        )
    }
    
    // MARK: - Body
    
    /// The main body rendering a tab view with custom view models and tab routing.
    internal var body: some View {
        TabView(selection: $appRouter.selectedTab) {
            Tab(AppRouter.Tab.recorder.title,
                systemImage: AppRouter.Tab.recorder.imageName,
                value: .recorder) {
                TabItems.recorderTab(isSelected: appRouter.selectedTab == .recorder)
            }
            
            Tab(AppRouter.Tab.profile.title,
                systemImage: AppRouter.Tab.profile.imageName,
                value: .profile) {
                TabItems.profileTab(isSelected: appRouter.selectedTab == .profile)
            }
            
            Tab(AppRouter.Tab.notes.title,
                systemImage: AppRouter.Tab.notes.imageName,
                value: .notes, role: .search) {
                TabItems.notesTab(isSelected: appRouter.selectedTab == .profile)
            }
        }
        .accentColor(Color.SupportColors.blue)
        .environmentObject(appRouter)
    }
        
}

// MARK: - Preview

#Preview {
    ContentView()
}
