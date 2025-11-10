//
//  ChipsView.swift
//  SmartDictophone
//
//  Created by Георгий Асеев on 29.10.2025.
//

import SwiftUI

struct ChipsView: View {
    private let text: String
    
    init(text: String) {
        self.text = text
    }
    
    internal var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(Color.LabelColors.white)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .clipShape(Capsule())
            .glassEffect(.regular.interactive().tint(Color.SupportColors.lightBlue))
    }
}

#Preview {
    ChipsView(text: "Apr 1, 2025")
}
