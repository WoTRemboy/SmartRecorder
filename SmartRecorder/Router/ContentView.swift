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
            NavigationStack(path: bindingForTab(.notes)) {
                NotesListView()
                    .environmentObject(appRouter)
                    .navigationDestination(for: AppRouter.Route.self) { route in
                        route.destinationView(in: .notes, appRouter: appRouter)
                    }
            }
            .tabItem {
                AppRouter.Tab.notes.image
                    .environment(\.symbolVariants, .none)
                Text(AppRouter.Tab.notes.title)
            }
            .tag(AppRouter.Tab.notes)
            
            NavigationStack(path: bindingForTab(.recorder)) {
                PlayerScreenView()
                    .environmentObject(appRouter)
                    .navigationDestination(for: AppRouter.Route.self) { route in
                        route.destinationView(in: .recorder, appRouter: appRouter)
                    }
            }
            .tabItem {
                AppRouter.Tab.recorder.image
                    .environment(\.symbolVariants, .none)
                Text(AppRouter.Tab.recorder.title)
            }
            .tag(AppRouter.Tab.recorder)
            
            NavigationStack(path: bindingForTab(.profile)) {
                ProfileView()
                    .environmentObject(appRouter)
                    .navigationDestination(for: AppRouter.Route.self) { route in
                        route.destinationView(in: .profile, appRouter: appRouter)
                    }
            }
            .tabItem {
                AppRouter.Tab.profile.image
                    .environment(\.symbolVariants, .none)
                Text(AppRouter.Tab.profile.title)
            }
            .tag(AppRouter.Tab.profile)
        }
        .accentColor(Color.SupportColors.blue)
    }
        
}

// MARK: - Preview

#Preview {
    ContentView()
}
