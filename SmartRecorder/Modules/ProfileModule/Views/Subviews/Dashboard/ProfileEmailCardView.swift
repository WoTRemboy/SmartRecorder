//
//  ProfileEmailCardView.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 03/12/2025.
//

import SwiftUI

struct EmailCardView: View {
    
    private let email: String
    
    init(email: String) {
        self.email = email
    }

    internal var body: some View {
        VStack(alignment: .center, spacing: 26) {
            logoView
            emailContent
        }
        .frame(maxWidth: .infinity)
    }
    
    private var logoView: some View {
        Circle()
            .fill(Color.SupportColors.lightBlue.opacity(0.3))
            .overlay {
                Text(initial)
                    .font(.system(size: 50, weight: .semibold))
                    .foregroundColor(Color.LabelColors.blue)
            }
            .frame(width: 120, height: 120)
    }
    
    private var emailContent: some View {
        VStack(spacing: 4) {
            Text(Texts.ProfilePage.Dashboard.email)
                .font(.title2(.medium))
                .foregroundColor(Color.LabelColors.secondary)
            
            Text(email)
                .font(.emailTitle())
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .foregroundColor(Color.LabelColors.blue)
                .truncationMode(.middle)
        }
    }
    
    private var initial: String {
        email.first.map { String($0).uppercased() } ?? "-"
    }
}


#Preview {
    EmailCardView(email: "example@gmail.com")
}
