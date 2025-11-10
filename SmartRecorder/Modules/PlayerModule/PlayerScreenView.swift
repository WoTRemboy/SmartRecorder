//
//  PlayerUIView.swift
//  SmartRecorder
//
//  Created by Виктория Мирошник on 21.10.2025.
//

import SwiftUI

struct PlayerScreenView: View {
    var body: some View {
        VStack {
            NavigationBarView()
            Spacer()
            AudioDescriptionView()
            ProgressBarView()
        }
        .background(Color.BackgroundColors.primary)
    }
}


#Preview {
    PlayerScreenView()
}
