//
//  OnboardingSkipButton.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 08/11/2025.
//

import SwiftUI

struct OnboardingSkipButton: View {
    
    private var viewModel: OnboardingViewModel
    private let action: () -> Void
    
    init(viewModel: OnboardingViewModel, action: @escaping () -> Void) {
        self.viewModel = viewModel
        self.action = action
    }
    
    internal var body: some View {
        if viewModel.buttonType != .getLocationPermission {
            skipButton
        } else {
            Color.clear
                .frame(height: 20)
        }
    }
    
    private var skipButton: some View {
        Button {
            withAnimation {
                action()
            }
        } label: {
            Text(Texts.OnboardingPage.skip)
                .foregroundStyle(Color.LabelColors.primary)
        }
        .buttonStyle(.glass)
        .frame(height: 20)
        .transition(.blurReplace)
        
        .padding(.horizontal)
        .padding(.top)
    }
}

#Preview {
    let viewModel = OnboardingViewModel()
    OnboardingSkipButton(viewModel: viewModel) {}
}
