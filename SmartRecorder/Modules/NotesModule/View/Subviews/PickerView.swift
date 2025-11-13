//
//  PickerView.swift
//  SmartDictophone
//
//  Created by Георгий Асеев on 29.10.2025.
//

import SwiftUI

struct PickerView: View {
    
    @Binding var selectedCategory: NoteFolder

    internal var body: some View {
        Picker(selection: $selectedCategory, label: Text("Категории")) {
            ForEach(NoteFolder.allCases, id: \.self) { folder in
                Text(folder.title)
            }
        }
        .pickerStyle(.segmented)
    }
}

#Preview {
    PickerView(selectedCategory: .constant(.all))
}
