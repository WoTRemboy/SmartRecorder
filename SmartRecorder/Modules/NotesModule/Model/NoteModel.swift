//
//  NoteModel.swift
//  SmartDictophone
//
//  Created by Георгий Асеев on 30.10.2025.
//

import Foundation
import Combine

class Note: Identifiable, ObservableObject, Equatable {
    let id = UUID()
    
    @Published var headline: String
    let subheadline: String
    let date: String
    let time: String
    let duration: String
    let category: String
    let location: String
    
    init(headline: String, subheadline: String, date: String, time: String, duration: String, category: String, location: String) {
            self.headline = headline
            self.subheadline = subheadline
            self.date = date
            self.time = time
            self.duration = duration
            self.category = category
            self.location = location
        }
    
    static func == (lhs: Note, rhs: Note) -> Bool {
        return lhs.id == rhs.id
    }
}
