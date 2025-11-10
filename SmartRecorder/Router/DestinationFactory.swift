//
//  DestinationFactory.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 10/11/2025.
//

import SwiftUI

extension AppRouter.Route {
    @ViewBuilder
    internal func destinationView(in tab: AppRouter.Tab, appRouter: AppRouter) -> some View {
        switch tab {
        case .notes:
            NotesTabDestinationFactory.view(for: self, appRouter: appRouter)
        case .recorder:
            RecorderTabDestinationFactory.view(for: self, appRouter: appRouter)
        case .profile:
            ProfileTabDestinationFactory.view(for: self, appRouter: appRouter)
        }
    }
}
