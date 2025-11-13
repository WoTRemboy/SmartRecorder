//
//  ProfileTabDestinationFactory.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 10/11/2025.
//

import SwiftUI

struct ProfileTabDestinationFactory {
    @ViewBuilder
    static func view(for route: AppRouter.Route, appRouter: AppRouter) -> some View {
        switch route {
        case .profile:
            ProfileView()
        default:
            EmptyView()
        }
    }
}
