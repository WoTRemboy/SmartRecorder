//
//  RecordsModel.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 05/12/2025.
//

import Foundation
import Combine

struct RecordResponse: Codable {
    let id: Int64
    let folderId: Int64?
    let title: String?
    let description: String?
    let datetime: Date?
    let latitude: Double?
    let longitude: Double?
    let duration: Int64?
    let category: String?
    let audioUrl: String?
    let createdAt: Date?
    let updatedAt: Date?
}

struct RecordsPage: Codable {
    let content: [RecordResponse]
    let totalElements: Int
    let totalPages: Int
}
