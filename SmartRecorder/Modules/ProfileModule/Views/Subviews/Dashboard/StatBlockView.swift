//
//  StatBlockView.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 03/12/2025.
//

import SwiftUI

struct StatBlockView: View {
    
    @State private var displayedValue: Double = 0
    
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
            
            CountingNumberText(value: displayedValue)
                .font(.system(size: 96, weight: .bold))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .foregroundColor(Color.SupportColors.purple)
                .frame(alignment: .center)
            
                .onAppear {
                    withAnimation(.easeOut(duration: 0.8)) {
                        displayedValue = Double(value)
                    }
                }
                .onChange(of: value) { _, newValue in
                    withAnimation(.easeOut(duration: 0.8)) {
                        displayedValue = Double(newValue)
                    }
                }
        }
    }
    
    private struct CountingNumberText: View, Animatable {
        var value: Double
        var animatableData: Double {
            get { value }
            set { value = newValue }
        }
        var body: some View {
            Text("\(Int(value))")
        }
    }
}

#Preview {
    StatBlockView(title: "Audio count", value: 20)
}
