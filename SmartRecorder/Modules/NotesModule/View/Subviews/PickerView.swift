//
//  PickerView.swift
//  SmartDictophone
//
//  Created by Георгий Асеев on 29.10.2025.
//

import SwiftUI

struct PickerView: View {
    
    @Binding var selectedCategory: String
    var audioCategories = ["Все", "Работа", "Учёба", "Личное"]
    
    
    
    var body: some View {
        Picker(selection: $selectedCategory, label: Text("Категории")) {
            ForEach(audioCategories, id: \.self) { category in
                Text(category)
            }
        }
        .pickerStyle(.segmented)
    }
}
