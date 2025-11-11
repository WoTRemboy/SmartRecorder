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
    static func notesTab(isSelected: Bool) -> some View {
        NavigationStack {
            NotesListView()
        }
    }
    
    /// Creates the recorder tab view.
    /// - Parameter isSelected: A boolean indicating whether the tab is currently selected.
    /// - Returns: A `PlayerScreenView` wrapped in a tab item.
    static func recorderTab(isSelected: Bool) -> some View {
        PlayerScreenView()
            .tabItem {
                Image.Tabbar.Recorder.system
                    .environment(\.symbolVariants, .none)
                Text(Texts.Tabbar.recorder)
            }
    }
    
    /// Creates the profile tab view.
    /// - Parameter isSelected: A boolean indicating whether the tab is currently selected.
    /// - Returns: A `ProfileView` wrapped in a tab item.
    static func profileTab(isSelected: Bool) -> some View {
        ProfileView()
            .tabItem {
                Image.Tabbar.Profile.system
                    .environment(\.symbolVariants, .none)
                Text(Texts.Tabbar.profile)
            }
    }
}

