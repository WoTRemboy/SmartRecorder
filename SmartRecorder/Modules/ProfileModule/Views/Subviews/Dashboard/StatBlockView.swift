//
//  StatBlockView.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 03/12/2025.
//

import SwiftUI

struct StatBlockView: View {
    
    private let title: String
    private let value: Int
    
    init(title: String, value: Int) {
        self.title = title
        self.value = value
    }
    
    internal var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2(.medium))
                .foregroundColor(Color.LabelColors.secondary)
            
            Text("\(value)")
                .font(.system(size: 96, weight: .bold))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .foregroundColor(Color.SupportColors.purple)
                .frame(alignment: .center)
        }
    }
}

#Preview {
    StatBlockView(title: "Audio count", value: 20)
}
