//
//  AudioDescriptionView.swift
//  SmartRecorder
//
//  Created by Виктория Мирошник on 22.10.2025.
//

import SwiftUI

struct AudioDescriptionView: View {
    
    @ObservedObject private var viewModel: PlayerViewModel
    
    init(viewModel: PlayerViewModel) {
        self.viewModel = viewModel
    }
        
    internal var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            noteDetailsView
            noteNameLabel
        }
        .padding(.horizontal, 20)
    }
    
    private var noteDetailsView: some View {
        GlassEffectContainer {
            HStack {
                ChipsView(text: DateService.formattedDate(viewModel.noteDate))
                ChipsView(text: DateService.formattedTime(viewModel.noteDate))
            }
        }
    }
    
    private var noteNameLabel: some View {
        Text(viewModel.noteName)
            .font(Font.title())
            .foregroundColor(Color.LabelColors.blue)
            .lineLimit(2)
            .padding(.bottom)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    let viewModel = PlayerViewModel(note: Note.mock)
    AudioDescriptionView(viewModel: viewModel)
}
