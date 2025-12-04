//
//  DateService.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 11.11.2025.
//

import Foundation

struct DateService {
    
    static func formattedToday() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = .current
        return formatter.string(from: Date())
    }
    
    static func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.locale = .current
        return formatter.string(from: date)
    }

    static func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = .current
        return formatter.string(from: date)
    }
}
