//
//  OnboardingScreenView.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 08/11/2025.
//

import SwiftUI
import SwiftData
import SwiftUIPager

struct OnboardingScreenView: View {
    
    @StateObject private var viewModel = OnboardingViewModel()
    
    /// Current page tracker for the pager.
    @StateObject private var page: Page = .first()
    
    internal var body: some View {
        if viewModel.skipOnboarding {
            PlayerScreenView()
        } else {
            VStack(alignment: .trailing) {
                skipButton
                content
                progressCircles
                actionButton
            }
            .onChange(of: page.index) { _, newValue in
                withAnimation {
                    viewModel.setupCurrentStep(newValue: newValue)
                }
            }
            .background(Color.BackgroundColors.primary)
        }
    }
    
    @ViewBuilder
    private var skipButton: some View {
        if viewModel.buttonType != .getLocationPermission {
            Button {
                withAnimation {
                    page.update(.moveToLast)
                }
            } label: {
                Text(Texts.OnboardingPage.skip)
                    .foregroundStyle(Color.LabelColors.primary)
            }
            .buttonStyle(.glass)
            .frame(height: 20)
            
            .padding(.horizontal)
            .padding(.top)
        } else {
            Color.clear
                .frame(height: 20)
        }
    }
    
    private var content: some View {
        Pager(page: page,
              data: viewModel.pages,
              id: \.self) { index in
            VStack(spacing: 16) {
                viewModel.steps[index].image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                
                Text(viewModel.steps[index].name)
                    .font(.largeTitle())
                    .padding(.top)
                
                Text(viewModel.steps[index].description)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .foregroundStyle(Color.LabelColors.primary)
            .tag(index)
        }
              .interactive(scale: 0.8)
              .itemSpacing(10)
              .itemAspectRatio(1.0)
        
              .swipeInteractionArea(.allAvailable)
              .multiplePagination()
              .horizontal()
    }
    
    private var progressCircles: some View {
        HStack {
            ForEach(viewModel.pages, id: \.self) { step in
                if step == page.index {
                    Circle()
                        .frame(width: 15, height: 15)
                        .foregroundStyle(Color.black)
                        .transition(.scale)
                } else {
                    Circle()
                        .frame(width: 10, height: 10)
                        .foregroundStyle(Color.LabelColors.disable)
                        .transition(.scale)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var actionButton: some View {
        Button {
            switch viewModel.buttonType {
            case .nextPage, .getMicrophonePermission:
                withAnimation {
                    page.update(.next)
                }
            case .getLocationPermission:
                withAnimation {
                    viewModel.transferToMainPage()
                }
            }
        } label: {
            Text(viewModel.buttonType.title)
                .contentTransition(.numericText())
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .buttonStyle(.glassProminent)
        
        .foregroundStyle(Color.white)
        .tint(Color.SupportColors.lightBlue)
        
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        
        .padding(.horizontal)
        .padding(.vertical, 30)
    }
}

#Preview {
    OnboardingScreenView()
}
