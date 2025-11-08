//
//  OnboardingActionButtonsView.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 08/11/2025.
//

import SwiftUI

struct OnboardingActionButtonsView: View {
    
    @ObservedObject private var viewModel: OnboardingViewModel
    
    private let action: () -> Void
    private let namespace: Namespace.ID
    
    init(viewModel: OnboardingViewModel, namespace: Namespace.ID, action: @escaping () -> Void) {
        self.viewModel = viewModel
        self.namespace = namespace
        self.action = action
    }
    
    internal var body: some View {
        GlassEffectContainer {
            HStack(spacing: 8) {
                if viewModel.buttonType != .nextPage {
                    skipPermissionButton
                }
                actionButton
            }
            .padding(.horizontal)
            .padding(.vertical, 30)
        }
    }
    
    private var actionButton: some View {
        Button {
            switch viewModel.buttonType {
            case .nextPage, .getMicrophonePermission:
                withAnimation {
                    action()
                }
            case .getLocationPermission:
                withAnimation {
                    viewModel.transferToMainPage()
                }
            }
        } label: {
            Text(viewModel.buttonType.title)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .buttonStyle(.glassProminent)
        .glassEffectID(Texts.GlassEffectId.Onboarding.permission, in: namespace)
        
        .foregroundStyle(Color.white)
        .tint(Color.SupportColors.lightBlue)
        
        .frame(height: 50)
        .frame(maxWidth: .infinity)
    }
    
    private var skipPermissionButton: some View {
        Button {
            withAnimation {
                action()
            }
        } label: {
            Text(Texts.OnboardingPage.skipPermission)
                .frame(maxWidth: 100, maxHeight: .infinity, alignment: .center)
        }
        .buttonStyle(.glassProminent)
        .glassEffectID(Texts.GlassEffectId.Onboarding.skipPermission, in: namespace)
        
        .tint(Color.SupportColors.lightBlue)
        
        .frame(height: 50)
    }
}

#Preview {
    let viewModel = OnboardingViewModel()
    let namespace = Namespace().wrappedValue
    OnboardingActionButtonsView(viewModel: viewModel, namespace: namespace) {}
}
