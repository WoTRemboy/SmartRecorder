//
//  ProfileCardFieldsModifier.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 03/12/2025.
//

import SwiftUI

struct CardFieldsModifier: ViewModifier {
    internal func body(content: Content) -> some View {
        content
            .padding(20)
            .glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

#Preview {
    RoundedRectangle(cornerRadius: 20)
        .modifier(CardFieldsModifier())
}
