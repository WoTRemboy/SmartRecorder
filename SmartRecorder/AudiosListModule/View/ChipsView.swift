//
//  ChipsView.swift
//  SmartDictophone
//
//  Created by Георгий Асеев on 29.10.2025.
//

import SwiftUI

struct ChipsView: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(Color.SupportColors.blue)
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background(Color.SupportColors.lightBlue)
            .clipShape(Capsule())
    }
}
