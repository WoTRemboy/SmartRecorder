//
//  ProfileAuthButton.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 03/12/2025.
//

import SwiftUI

struct AuthButton: View {
    
    private let isLoading: Bool
    private let title: String
    private let action: () -> Void
    
    init(isLoading: Bool, title: String, action: @escaping () -> Void) {
        self.isLoading = isLoading
        self.title = title
        self.action = action
    }
    
    internal var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .frame(height: 50)
                    .foregroundStyle(.clear)
                
                Text(title)
                    .font(Font.title2(.semibold))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }
        }
        .buttonStyle(.glassProminent)
        .tint(Color.SupportColors.blue)
        .disabled(isLoading)
    }
}

#Preview {
    AuthButton(isLoading: false, title: "Sign Up") {}
}
