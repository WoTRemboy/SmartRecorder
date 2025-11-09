//
//  TabRouter.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 09/11/2025.
//

import Combine

/// A router class that manages the currently selected tab in the tab bar.
final class TabRouter: ObservableObject {
    
    /// The currently selected tab. Defaults to `.notes`.
    @Published var selectedTab: Tab = .notes
    
    /// The available tabs in the app.
    enum Tab {
        case notes
        case recorder
        case profile
    }
}
