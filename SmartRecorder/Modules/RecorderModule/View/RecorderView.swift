//
//  RecorderView.swift
//  SmartRecorder
//
//  Created by Виктория Мирошник on 29.10.2025.
//

import SwiftUI

struct RecorderView: View {
    
    @EnvironmentObject private var viewModel: RecorderViewModel
    @Namespace private var namespace
    
    internal var body: some View {
        VStack {
            RecorderDetailsView()
                .padding(.top, 40)
            
            if !viewModel.isRecording {
                RecorderStartView(namespace: namespace)
                    .frame(maxHeight: .infinity, alignment: .center)
            }
            
            if viewModel.isRecording {
                RecorderStopView(namespace: namespace)
                    .frame(maxHeight: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.BackgroundColors.primary)
        .sensoryFeedback(.impact, trigger: viewModel.isRecording)
        
        .task {
            await viewModel.ensureLocation()
        }
        
        .alert(Texts.OnboardingPage.LocationAlert.title, isPresented: $viewModel.showLocationPermissionAlert) {
            locationAlertButtons
        } message: {
            Text(Texts.OnboardingPage.LocationAlert.content)
        }
    }
    
    @ViewBuilder
    private var locationAlertButtons: some View {
        Button(Texts.OnboardingPage.LocationAlert.settings) {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }
        Button(Texts.OnboardingPage.LocationAlert.cancel, role: .cancel) {}
    }
}

#Preview {
    RecorderView()
        .environmentObject(RecorderViewModel())
}
