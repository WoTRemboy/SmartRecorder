//
//  PlayerUIView.swift
//  SmartRecorder
//
//  Created by Виктория Мирошник on 21.10.2025.
//

import SwiftUI

struct PlayerScreenView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    var body: some View {
        ZStack {
//      есть баг с жидким стеклом при переключении на темную            тему
//            colorScheme == .dark ? nil :                                    Color.BackgroundColors.primary
//                    .ignoresSafeArea(.all)
            VStack {
                NavigationBarView()
                Spacer()
                AudioDescriptionView()
                ProgressBarView()
            }
        }
        .background(Color.BackgroundColors.primary
            .ignoresSafeArea(.all))
    }
}


#Preview {
    PlayerScreenView()
}
