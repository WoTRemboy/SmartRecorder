//
//  EntityModel.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 16/11/2025.
//

import Foundation
import CoreData

struct Location: Hashable, Sendable {
    var latitude: Double
    var longitude: Double
    var cityName: String?
    var streetName: String?
}

struct Note: Identifiable, Hashable {
    let id: UUID
    var serverId: String?
    var folderId: String?
    var title: String
    var transcription: String?
    var audioPath: String?
    var createdAt: Date
    var updatedAt: Date
    var duration: Int?
    var location: Location?
}

struct User: Identifiable, Hashable {
    let id: UUID
    var email: String?
    var firstName: String?
    var lastName: String?
    var username: String?
    var countRecords: Int32
    var countMinutes: Int32
}

// MARK: - Mapping helpers

extension LocationEntity {
    func toDomain() -> Location {
        Location(
            latitude: self.latitude,
            longitude: self.longitude,
            cityName: self.cityName,
            streetName: self.streetName
        )
    }

    func apply(from location: Location) {
        self.latitude = location.latitude
        self.longitude = location.longitude
        self.cityName = location.cityName
        self.streetName = location.streetName
    }
}

extension NoteEntity {
    func toDomain() -> Note {
        Note(
            id: self.id ?? UUID(),
            serverId: self.serverId,
            folderId: self.folderId,
            title: self.title ?? "",
            transcription: self.transcription,
            audioPath: self.audioPath,
            createdAt: self.createdAt ?? .init(),
            updatedAt: self.updatedAt ?? .init(),
            duration: Int(self.duration),
            location: self.location?.toDomain()
        )
    }

    func apply(from note: Note) {
        self.id = note.id
        self.serverId = note.serverId
        self.folderId = note.folderId
        self.title = note.title
        self.transcription = note.transcription
        self.audioPath = note.audioPath
        self.createdAt = note.createdAt
        self.updatedAt = note.updatedAt
        
        if let duration = note.duration {
            self.duration = Int32(duration)
        } else {
            self.duration = -9
        }

        if let location = note.location {
            let locationEntity = self.location ?? LocationEntity(context: self.managedObjectContext!)
            locationEntity.apply(from: location)
            self.location = locationEntity
        } else {
            self.location = nil
        }
    }
}

extension UserEntity {
    func toDomain() -> User {
        User(
            id: self.id ?? UUID(),
            email: self.email,
            firstName: self.firstName,
            lastName: self.lastName,
            username: self.username,
            countRecords: self.countRecords,
            countMinutes: self.countMinutes
        )
    }

    func apply(from user: User) {
        self.id = user.id
        self.email = user.email
        self.firstName = user.firstName
        self.lastName = user.lastName
        self.username = user.username
    }
}

extension Note {
    internal static let mock = Note(
        id: UUID(),
        serverId: nil,
        folderId: "note_folder_work",
        title: "Sample Note Title",
        transcription: nil,
        audioPath: nil,
        createdAt: .now,
        updatedAt: .now,
        duration: 20,
        location: Location(latitude: 0, longitude: 0, cityName: "Sample City", streetName: "Sample Street")
    )
}
