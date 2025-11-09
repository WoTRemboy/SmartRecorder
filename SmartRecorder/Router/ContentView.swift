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
    @StateObject private var router = TabRouter()
    
    // MARK: - Body
    
    /// The main body rendering a tab view with custom view models and tab routing.
    internal var body: some View {
        TabView(selection: $router.selectedTab) {
            TabItems.notesTab(isSelected: router.selectedTab == .notes)
                .tag(TabRouter.Tab.notes)
            
            TabItems.recorderTab(isSelected: router.selectedTab == .recorder)
                .tag(TabRouter.Tab.recorder)
            
            TabItems.profileTab(isSelected: router.selectedTab == .profile)
                .tag(TabRouter.Tab.profile)
        }
        .accentColor(Color.SupportColors.blue)
        .environmentObject(router)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
