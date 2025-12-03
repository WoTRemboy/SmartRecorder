//
//  ProfileInfoToast.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 03/12/2025.
//

import SwiftUI

struct InfoToast: View {
    
    @State private var visible = false

    private let text: String
    private var onDismiss: () -> Void
    
    init(text: String, onDismiss: @escaping () -> Void) {
        self.text = text
        self.onDismiss = onDismiss
    }
    
    internal var body: some View {
        ZStack {
            if visible {
                Text(text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .glassEffect(.regular)
                    .transition(
                        .move(edge: .top)
                        .combined(with: .opacity)
                    )
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.1), value: visible)
        
        .onAppear {
            withAnimation {
                visible = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    visible = false
                }
                onDismiss()
            }
        }
    }
}

#Preview {
    InfoToast(text: "completed") {}
}
