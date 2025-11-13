//
//  AudioDescriptionView.swift
//  SmartRecorder
//
//  Created by Виктория Мирошник on 22.10.2025.
//

import SwiftUI

struct AudioDescriptionView: View {
    @State private var date = Date()
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 5) {
                ZStack {
                    Capsule()
                        .frame(width: 82, height: 26)
                        .foregroundColor(.SupportColors.lightBlue.opacity(0.3))
                    
                    Text("Apr 1, 2025")
                        .font(Font.caption())
                        .foregroundColor(.SupportColors.blue)
                    
                }
                ZStack {
                    Capsule()
                        .frame(width: 63, height: 26)
                        .foregroundColor(.SupportColors.lightBlue.opacity(0.3))
                    Text("9:41 AM")
                        .font(Font.caption())
                        .foregroundColor(.SupportColors.blue)
                }
            }
            
            Text("Исследования конкурентов и организация взаимодействий")
                .font(Font.title())
                .foregroundColor(.SupportColors.blue)
                .lineLimit(2)
                .padding(.bottom)
                .frame(maxWidth: .infinity, alignment: .leading)
            
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    AudioDescriptionView()
}
