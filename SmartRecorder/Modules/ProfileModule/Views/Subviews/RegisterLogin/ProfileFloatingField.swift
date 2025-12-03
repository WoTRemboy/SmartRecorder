//
//  ProfileFloatingField.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 03/12/2025.
//

import SwiftUI

struct FloatingField: View {
    
    @Binding private var text: String
    
    private let title: String
    private var isSecure: Bool
    private var keyboard: UIKeyboardType
    private var placeholder: String
    
    init(title: String,
         text: Binding<String>,
         isSecure: Bool = false,
         keyboard: UIKeyboardType = .default,
         placeholder: String = "") {
        
        self.title = title
        self._text = text
        self.isSecure = isSecure
        self.keyboard = keyboard
        self.placeholder = placeholder
    }
    
    internal var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.LabelColors.purple)
            
            secureTextFieldGroup
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.SupportColors.lightBlue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .foregroundStyle(Color.LabelColors.primary)
        }
    }
    
    private var secureTextFieldGroup: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textContentType(.password)
            } else {
                TextField(placeholder, text: $text)
                    .textInputAutocapitalization(.never)
                    .keyboardType(keyboard)
                    .textContentType(.emailAddress)
            }
        }
    }
}

#Preview {
    FloatingField(
        title: "Email",
        text: .constant(""),
        isSecure: false,
        keyboard: .default,
        placeholder: "Enter your email"
    )
}
