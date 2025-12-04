//
//  RecorderDetailsView.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 13/11/2025.
//

import Foundation
import SwiftUI
import CoreLocation
import MapKit

struct RecorderDetailsView: View {
    @EnvironmentObject private var viewModel: RecorderViewModel
    
    internal var body: some View {
        VStack(spacing: 5) {
            dateView
            locationView
        }
    }
    
    private var dateView: some View {
        HStack {
            Image.RecorderPage.date
            Text(DateService.formattedToday())
        }
        .font(Font.title2())
        .foregroundStyle(Color.LabelColors.purple)
        .padding(.horizontal)
    }
    
    private var locationView: some View {
        HStack {
            Image.RecorderPage.location
            Text(locationText)
                .contentTransition(.numericText())
        }
        .font(Font.title2())
        .foregroundColor(Color.LabelColors.purple)
        .padding(.horizontal)
        .animation(.easeInOut(duration: 0.2), value: locationText)
        .onTapGesture {
            viewModel.toggleShowLocationPermissionAlert()
        }
    }
    
    private var locationText: String {
        if let street = viewModel.streetName {
            return street
        }
        return Texts.RecorderPage.location
    }
}

#Preview {
    RecorderDetailsView()
        .environmentObject(RecorderViewModel())
}
