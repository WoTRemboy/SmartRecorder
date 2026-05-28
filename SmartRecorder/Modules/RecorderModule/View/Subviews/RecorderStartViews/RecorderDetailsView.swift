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
            participantsView
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
    
    private var participantsView: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.2.fill")
            Button {
                viewModel.decrementParticipants()
            } label: {
                Image(systemName: "minus.circle")
            }
            .disabled(viewModel.participantCount <= 1)

            Text("\(viewModel.participantCount)")
                .monospacedDigit()
                .frame(minWidth: 24)
                .contentTransition(.numericText(value: Double(viewModel.participantCount)))
                .animation(.default, value: viewModel.participantCount)

            Button {
                viewModel.incrementParticipants()
            } label: {
                Image(systemName: "plus.circle")
            }
        }
        .font(Font.title2())
        .foregroundStyle(Color.LabelColors.purple)
        .padding(.horizontal)
    }

    private var locationText: String {
        if let street = viewModel.streetName { return street }
        Task { @MainActor in
            if let names = await LocationService.shared.fetchCurrentPlaceNames() {
                if viewModel.streetName == nil { viewModel.streetName = names.street }
                if viewModel.cityName == nil { viewModel.cityName = names.city }
            }
        }
        return Texts.RecorderPage.location
    }
}

#Preview {
    RecorderDetailsView()
        .environmentObject(RecorderViewModel())
}
