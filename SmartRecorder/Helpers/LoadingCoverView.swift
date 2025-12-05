//
//  LoadingCoverView.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 05/12/2025.
//

import SwiftUI

struct LoadingCoverView: View {
    
    internal var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.6)
                .tint(Color.SupportColors.blue)
            Text("Загрузка...")
                .font(.headline)
                .foregroundStyle(Color.SupportColors.blue)
        }
        .padding(32)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

#Preview {
    LoadingCoverView()
}
