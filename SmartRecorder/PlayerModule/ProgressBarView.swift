//
//  ProgressBarView.swift
//  SmartRecorder
//
//  Created by Виктория Мирошник on 22.10.2025.
//

import SwiftUI

struct ProgressBarView: View {
    var body: some View {
        VStack {
            ZStack(alignment: .leading) {
                Capsule()
                    .foregroundColor(.SupportColors.lightBlue)
                    .frame(width: 100, height: 7)
                Capsule().foregroundColor(.SupportColors.lightBlue).opacity(0.29)
                
            }
            .frame(height: 7)
            .padding(.bottom, 13)
            
            HStack {
                Text("00:00")
                Spacer()
                Text("-00:00")
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.SupportColors.blue.opacity(0.75))
            
            HStack(spacing: 20) {
                Button {
                    
                }
                label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 20, weight: .regular))
                }
                .padding(20)
                .glassEffect(.regular.interactive(), in: .circle)
                
                Button {
                    
                }
                label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 40, weight: .regular))
                }
                .padding(30)
                .glassEffect(.regular.interactive(), in: .circle)
                
                Button {
                    
                }
                label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 20, weight: .regular))
                }
                .padding(20)
                .glassEffect(.regular.interactive(), in: .circle)
                
            }
            .foregroundColor(.SupportColors.blue)
            .padding(.all)
           

            
        }
        .padding(.vertical, 25)
        .padding(.horizontal,20)
    }
}

#Preview {
    ProgressBarView()
}
