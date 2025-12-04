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
        .alert(Texts.RecorderPage.SaveSheet.success, isPresented: $viewModel.showSaveSuccessAlert) {
            saveAlertButton
        } message: {
            Text(Texts.RecorderPage.SaveSheet.successMessage)
        }
        .alert(Texts.RecorderPage.SaveSheet.failure, isPresented: $viewModel.showSaveErrorAlert) {
            saveAlertButton
        } message: {
            Text(Texts.RecorderPage.SaveSheet.failureMessage)
        }
        .sheet(isPresented: $viewModel.showSaveSheetView) {
            SaveSheetView()
                .presentationDetents([.height(450)])
                .interactiveDismissDisabled()
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
    
    private var saveAlertButton: some View {
        Button(Texts.RecorderPage.SaveSheet.ok, role: .cancel) {}
    }
}

#Preview {
    RecorderView()
        .environmentObject(RecorderViewModel())
}
