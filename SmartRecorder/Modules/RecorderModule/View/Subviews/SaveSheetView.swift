//
//  SaveSheetView.swift
//  SmartRecorder
//
//  Created by Виктория Мирошник on 02.11.2025.
//

import SwiftUI

struct SaveSheetView: View {
    var body: some View {
        VStack {
            Capsule()
                .frame(height: 67)
                .overlay {
                    Text("Работа")
                        .foregroundStyle(Color.SupportColors.purple)
                        .font(Font.body())
                        
                }
                .foregroundStyle(Color.BackgroundColors.primary)
        }
    }
}

#Preview {
    SaveSheetView()
}
