//
//  NotesTabDestinationFactory.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 10/11/2025.
//

import SwiftUI

struct NotesTabDestinationFactory {
    @ViewBuilder
    static func view(for route: AppRouter.Route, appRouter: AppRouter) -> some View {
        switch route {
        case .notesList:
            NotesListView()
        case .noteDetails(let note):
            SingleAudioDescriptionView(note: note)
                .environmentObject(appRouter)
        default:
            EmptyView()
        }
    }
}
