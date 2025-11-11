//
//  AppRouter.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 09/11/2025.
//

import Combine
import SwiftUI

/// A router class that manages the currently selected tab in the tab bar.
final class AppRouter: ObservableObject {
    
    /// The currently selected tab. Defaults to `.notes`.
    @Published internal var selectedTab: Tab = .recorder
    @Published internal var navigationPaths: [Tab: [Route]] = Tab.allCases.reduce(into: [:]) { $0[$1] = [] }
    
    /// The available tabs in the app.
    enum Tab: CaseIterable, Hashable {
        case notes
        case recorder
        case profile
        
        internal var title: String {
            switch self {
            case .notes: return Texts.Tabbar.notes
            case .recorder: return Texts.Tabbar.recorder
            case .profile: return Texts.Tabbar.profile
            }
        }
        
        internal var image: Image {
            switch self {
            case .notes: return Image.Tabbar.Notes.system
            case .recorder: return Image.Tabbar.Recorder.system
            case .profile: return Image.Tabbar.Profile.system
            }
        }
        
        internal var imageName: String {
            switch self {
            case .notes: return "list.bullet.rectangle"
            case .recorder: return "play.circle"
            case .profile: return "person"
            }
        }
    }
    
    enum Route: Hashable {
        case notesList
        case noteDetails
        
        case recorder
        case profile
    }
    
    internal func push(_ route: Route, in tab: Tab) {
        navigationPaths[tab, default: []].append(route)
    }
    
    internal func pop(in tab: Tab) {
        _ = navigationPaths[tab]?.popLast()
    }
    
    internal func popToRoot(in tab: Tab) {
        navigationPaths[tab] = []
    }
    
    internal func setTab(to tab: Tab) {
        if selectedTab == tab {
            popToRoot(in: tab)
        } else {
            selectedTab = tab
        }
    }
}
