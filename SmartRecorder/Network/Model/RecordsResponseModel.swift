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

    enum CodingKeys: String, CodingKey {
        case id
        case folderId
        case title
        case description
        case datetime
        case latitude
        case longitude
        case duration
        case category
        case audioUrl
        case createdAt
        case updatedAt
    }
}

extension RecordResponse {
    private static let serverDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return formatter
    }()

    private static let createdAtFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        return formatter
    }()

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int64.self, forKey: .id)
        folderId = try container.decodeIfPresent(Int64.self, forKey: .folderId)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        duration = try container.decodeIfPresent(Int64.self, forKey: .duration)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        audioUrl = try container.decodeIfPresent(String.self, forKey: .audioUrl)

        // datetime: "yyyy-MM-dd'T'HH:mm:ss"
        if let datetimeString = try container.decodeIfPresent(String.self, forKey: .datetime) {
            datetime = RecordResponse.serverDateFormatter.date(from: datetimeString)
        } else {
            datetime = nil
        }

        // createdAt: "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        if let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = RecordResponse.createdAtFormatter.date(from: createdAtString)
        } else {
            createdAt = nil
        }

        // updatedAt: "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        if let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            updatedAt = RecordResponse.createdAtFormatter.date(from: updatedAtString)
        } else {
            updatedAt = nil
        }
    }
}

struct RecordsPage: Codable {
    let content: [RecordResponse]
    let totalElements: Int
    let totalPages: Int
}
