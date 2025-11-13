//
//  NavigationBarUIView.swift
//  SmartRecorder
//
//  Created by Виктория Мирошник on 21.10.2025.
//

import SwiftUI

struct NavigationBarView: View {
    var body: some View {
        
        HStack {
            Button {
                
            }
            label: {
                Image.NavigationBar.chevronDown
                    .font(.system(size: 30, weight: .light))
            }
            Spacer()
            Button {
                
            } label: {
                Label(Texts.NavigationBar.location, systemImage: "location.fill")
                    .font(Font.title2())
            }

            Spacer()
            Button {
                
            } label: {
                Image.NavigationBar.squareAndArrowUp
                    .font(.system(size: 24, weight: .light))
            }
        }
        .foregroundStyle(Color.LabelColors.purple)
        .padding()
        .frame(height: 59)
    }
}

#Preview {
    NavigationBarView()
}
