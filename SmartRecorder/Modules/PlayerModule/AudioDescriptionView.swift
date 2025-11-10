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
                        .font(.system(size: 12.5))
                        .foregroundColor(.SupportColors.blue)
                    
                }
                ZStack {
                    Capsule()
                        .frame(width: 63, height: 26)
                        .foregroundColor(.SupportColors.lightBlue.opacity(0.3))
                    Text("9:41 AM")
                        .font(.system(size: 12.5))
                        .foregroundColor(.SupportColors.blue)
                }
            }
            
            Text("Исследования конкурентов и организация взаимодействий")
                .font(.system(size: 20, weight: .bold))
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
