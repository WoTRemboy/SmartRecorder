//
//  TabItems.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 09/11/2025.
//

import SwiftUI

/// A utility struct providing configured tab items for the main tab bar.
struct TabItems {
    
    /// Creates the notes tab view.
    /// - Parameter isSelected: A boolean indicating whether the tab is currently selected.
    /// - Returns: A `NotesView` wrapped in a tab item.
    static func notesTab(appRouter: AppRouter) -> some View {
        NotesListView()
            .environmentObject(appRouter)
            .navigationDestination(for: AppRouter.Route.self) { route in
                route.destinationView(in: .notes, appRouter: appRouter)
            }
    }
    
    /// Creates the recorder tab view.
    /// - Parameter isSelected: A boolean indicating whether the tab is currently selected.
    /// - Returns: A `PlayerScreenView` wrapped in a tab item.
    static func recorderTab(appRouter: AppRouter) -> some View {
        PlayerScreenView()
            .environmentObject(appRouter)
            .navigationDestination(for: AppRouter.Route.self) { route in
                route.destinationView(in: .recorder, appRouter: appRouter)
            }
    }
    
    /// Creates the profile tab view.
    /// - Parameter isSelected: A boolean indicating whether the tab is currently selected.
    /// - Returns: A `ProfileView` wrapped in a tab item.
    static func profileTab(appRouter: AppRouter) -> some View {
        ProfileView()
            .environmentObject(appRouter)
            .navigationDestination(for: AppRouter.Route.self) { route in
                route.destinationView(in: .profile, appRouter: appRouter)
            }
    }
}

