//
//  RecordsService.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 03/12/2025.
//

import Foundation
import OSLog
import Alamofire

private let logger = Logger(subsystem: "com.transono.recorder", category: "RecordsService")

final class RecordsService {
    internal static let shared = RecordsService()
    
    private let session: URLSession = .shared
    private let baseURL: URL = URL(string: "http://localhost:8888")!
    
    private static let serverDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()
    
    private static let createdAtFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        return formatter
    }()

    private func authorizedHeaders(accept: String = "application/json") async throws -> HTTPHeaders {
        let token = try await AuthorizationService.shared.validAccessToken()
        return [
            .authorization(bearerToken: token),
            .accept(accept)
        ]
    }

    private func jsonDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(Self.serverDateFormatter)
        return decoder
    }

    private func decode<T: Decodable>(_ type: T.Type, from response: AFDataResponse<Data>) throws -> T {
        guard let http = response.response else {
            throw ServiceError.invalidResponse
        }

        switch response.result {
        case .success(let data):
            if (200..<300).contains(http.statusCode) {
                return try jsonDecoder().decode(type, from: data)
            }

            if let api = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw ServiceError.apiError(statusCode: http.statusCode, message: api.message)
            }

            let bodyString = String(data: data, encoding: .utf8) ?? "(non-utf8 body)"
            throw ServiceError.httpError(statusCode: http.statusCode, body: bodyString)
        case .failure(let afError):
            throw afError
        }
    }

    private func validateSuccess(_ response: AFDataResponse<Data>) throws {
        guard let http = response.response else {
            throw ServiceError.invalidResponse
        }

        switch response.result {
        case .success(let data):
            guard (200..<300).contains(http.statusCode) else {
                if let api = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                    throw ServiceError.apiError(statusCode: http.statusCode, message: api.message)
                }
                throw ServiceError.httpError(statusCode: http.statusCode, body: String(data: data, encoding: .utf8) ?? "")
            }
        case .failure(let afError):
            throw afError
        }
    }
    
    internal func uploadRecord(fileURL: URL, name: String, datetime: Date, category: String, folderId: Int, place: String? = nil) async throws -> RecordResponse {
        
        let url = baseURL.appendingPathComponent("records")
        
        let token = try await AuthorizationService.shared.validAccessToken()
        let headers: HTTPHeaders = [
            .authorization(bearerToken: token),
            .accept("application/json")
        ]
        
        let fileName = fileURL.lastPathComponent.isEmpty ? "record.m4a" : fileURL.lastPathComponent
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let datetimeFormatted = formatter.string(from: datetime)
        
        let uploadRequest = AF.upload(multipartFormData: { form in
            // file part
            form.append(fileURL, withName: "recordFile", fileName: fileName, mimeType: "audio/m4a")
            
            // text fields
            if let nameData = name.data(using: .utf8) {
                form.append(nameData, withName: "name")
            }
            if let dateData = datetimeFormatted.data(using: .utf8) {
                form.append(dateData, withName: "datetime")
            }
            if let categoryData = category.data(using: .utf8) {
                form.append(categoryData, withName: "category")
            }
            if let place = place, !place.isEmpty, let placeData = place.data(using: .utf8) {
                form.append(placeData, withName: "place")
            }
        }, to: url, method: .post, headers: headers)
        
        let response = await uploadRequest.serializingData().response
        
        guard let http = response.response else {
            throw ServiceError.invalidResponse
        }
        
        switch response.result {
        case .success(let data):
            if (200..<300).contains(http.statusCode) {
                let decoder = JSONDecoder()
                let recordResponse = try decoder.decode(RecordResponse.self, from: data)
                logger.info("Upload succeeded with record id: \(recordResponse.id, privacy: .private)")
                return recordResponse
            } else {
                let decoder = JSONDecoder()
                if let api = try? decoder.decode(APIErrorResponse.self, from: data) {
                    throw ServiceError.apiError(statusCode: http.statusCode, message: api.message)
                } else {
                    let bodyString = String(data: data, encoding: .utf8) ?? "(non-utf8 body)"
                    throw ServiceError.httpError(statusCode: http.statusCode, body: bodyString)
                }
            }
        case .failure(let afError):
            throw afError
        }
    }
    
    internal func fetchRecords(search: String? = nil, folderId: Int? = nil, page: Int = 0, size: Int = 20) async throws -> RecordsPage {
        
        let url = baseURL.appendingPathComponent("records")
        
        let token = try await AuthorizationService.shared.validAccessToken()
        let headers: HTTPHeaders = [
            .authorization(bearerToken: token),
            .accept("application/json")
        ]
        
        var params: [String: Any] = [:]
        if let search = search, !search.isEmpty {
            params["search"] = search
        }
        if let folderId = folderId {
            params["folderId"] = folderId
        }
        params["page"] = page
        params["size"] = size
        
        let request = AF.request(url, method: .get, parameters: params, encoding: URLEncoding.default, headers: headers)
        
        let response = await request.serializingData().response
        
        guard let http = response.response else {
            throw ServiceError.invalidResponse
        }
        
        switch response.result {
        case .success(let data):
            if (200..<300).contains(http.statusCode) {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted(Self.serverDateFormatter)
                let recordsPage = try decoder.decode(RecordsPage.self, from: data)
                logger.info("Decoded records page: totalPages = \(recordsPage.totalPages, privacy: .public), totalElements = \(recordsPage.totalElements, privacy: .public), contentCount = \(recordsPage.content.count, privacy: .public)")
                
                // Persist to Core Data
                let noteService = NoteEntityService.shared
                for record in recordsPage.content {
                    let serverId = String(record.id)
                    // Try to find existing note by serverId to preserve stable UUID
                    let existing = try await noteService.fetch(NoteFetchOptions(query: NoteQuery(serverId: serverId), limit: 1))
                    let noteId = existing.first?.id ?? UUID()
                    let audioPathToUse: String? = {
                        if let local = existing.first?.audioPath, !local.isEmpty {
                            return local
                        }
                        return String()
                    }()
                    let durationToUse: Int = {
                        if let local = existing.first?.duration, local > 0 {
                            return local
                        }
                        return 0
                    }()
                    let remoteUpdatedAt = record.updatedAt ?? record.datetime ?? Date.distantPast
                    let transcriptionToUse: String? = {
                        if let local = existing.first,
                           let localTranscription = local.transcription,
                           !localTranscription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                           local.updatedAt > remoteUpdatedAt {
                            return localTranscription
                        }

                        return record.description
                    }()

                    let loc: Location? = {
                        if let lat = record.latitude, let lon = record.longitude {
                            return Location(latitude: lat, longitude: lon, cityName: nil, streetName: nil)
                        }
                        return nil
                    }()

                    let note = Note(
                        id: noteId,
                        serverId: serverId,
                        folderId: record.category,
                        title: record.title ?? "",
                        transcription: transcriptionToUse,
                        audioPath: audioPathToUse,
                        createdAt: record.createdAt ?? record.datetime ?? Date(),
                        updatedAt: max(existing.first?.updatedAt ?? Date.distantPast, record.updatedAt ?? record.datetime ?? Date()),
                        duration: durationToUse,
                        location: loc
                    )
                    _ = try await noteService.upsert(note)
                }
                
                logger.info("Saved/updated \(recordsPage.content.count, privacy: .public) records to Core Data")

                return recordsPage
            } else {
                logger.error("API error status=\(http.statusCode, privacy: .public)")
                let decoder = JSONDecoder()
                if let api = try? decoder.decode(APIErrorResponse.self, from: data) {
                    throw ServiceError.apiError(statusCode: http.statusCode, message: api.message)
                } else {
                    let bodyString = String(data: data, encoding: .utf8) ?? "(non-utf8 body)"
                    throw ServiceError.httpError(statusCode: http.statusCode, body: bodyString)
                }
            }
        case .failure(let afError):
            logger.error("Network failure: \(String(describing: afError), privacy: .private)")
            throw afError
        }
    }

    internal func fetchRecord(recordId: Int64) async throws -> RecordResponse {
        let url = baseURL.appendingPathComponent("records/\(recordId)")
        let headers = try await authorizedHeaders()
        let request = AF.request(url, method: .get, headers: headers)
        return try decode(RecordResponse.self, from: await request.serializingData().response)
    }

    internal func fetchRecordSummary(recordId: Int64) async throws -> RecordSummaryResponse {
        let url = baseURL.appendingPathComponent("records/\(recordId)/summary")
        let headers = try await authorizedHeaders()
        let request = AF.request(url, method: .get, headers: headers)
        return try decode(RecordSummaryResponse.self, from: await request.serializingData().response)
    }

    internal func fetchRecordStatuses(recordId: Int64) async throws -> [ProcessingStatusResponse] {
        let url = baseURL.appendingPathComponent("records/\(recordId)/statuses")
        let headers = try await authorizedHeaders()
        let request = AF.request(url, method: .get, headers: headers)
        return try decode([ProcessingStatusResponse].self, from: await request.serializingData().response)
    }

    internal func shareRecord(recordId: Int64, email: String?, userId: String?, role: RecordAccessRole) async throws {
        let url = baseURL.appendingPathComponent("records/\(recordId)/share")
        let headers = try await authorizedHeaders()
        var payload: [String: String] = ["role": role.rawValue]
        if let userId {
            payload["userId"] = userId
        }
        if let email {
            payload["email"] = email
        }
        let request = AF.request(url, method: .post, parameters: payload, encoder: JSONParameterEncoder.default, headers: headers)
        try validateSuccess(await request.serializingData().response)
    }

    internal func fetchSharedUsers(recordId: Int64) async throws -> [SharedRecordUserResponse] {
        let url = baseURL.appendingPathComponent("records/\(recordId)/shared-users")
        let headers = try await authorizedHeaders()
        let request = AF.request(url, method: .get, headers: headers)
        return try decode([SharedRecordUserResponse].self, from: await request.serializingData().response)
    }

    internal func revokeSharedUser(recordId: Int64, userId: String) async throws {
        let url = baseURL.appendingPathComponent("records/\(recordId)/shared-users/\(userId)")
        let headers = try await authorizedHeaders()
        let request = AF.request(url, method: .delete, headers: headers)
        try validateSuccess(await request.serializingData().response)
    }

    internal func fetchSharedRecords() async throws -> [SharedRecordResponse] {
        let url = baseURL.appendingPathComponent("records/shared")
        let headers = try await authorizedHeaders()
        let request = AF.request(url, method: .get, headers: headers)
        return try decode([SharedRecordResponse].self, from: await request.serializingData().response)
    }

    // MARK: - Audio Downloading

    /// Returns a directory URL where audio files are stored, creating it if needed.
    private func audioDirectoryURL() throws -> URL {
        let dir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("Audio", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// Downloads an audio file for the given record ID and saves it locally. Also updates Core Data `Note.audioPath` for the matching `serverId`.
    @discardableResult
    internal func downloadRecordAudio(recordId: Int64) async throws -> URL {

        let url = baseURL.appendingPathComponent("records/\(recordId)/audio")

        let token = try await AuthorizationService.shared.validAccessToken()
        let headers: HTTPHeaders = [
            .authorization(bearerToken: token),
            .accept("audio/m4a")
        ]

        let fileName = "record-\(recordId).m4a"
        let destinationURL: URL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName, isDirectory: false)

        let destination: DownloadRequest.Destination = { _, _ in
            return (destinationURL, [.removePreviousFile, .createIntermediateDirectories])
        }

        let download = AF.download(url, method: .get, headers: headers, to: destination)

        let response = await download.serializingDownloadedFileURL().response

        guard let http = response.response else {
            throw ServiceError.invalidResponse
        }

        switch response.result {
        case .success(let fileURL):
            logger.info("Audio saved to: \(fileURL.path(percentEncoded: false), privacy: .private)")
            // Update Core Data note with this serverId
            let noteService = NoteEntityService.shared
            let serverId = String(recordId)
            if let existing = try await noteService.fetch(NoteFetchOptions(query: NoteQuery(serverId: serverId), limit: 1)).first {
                var updated = existing
                updated.audioPath = fileName
                _ = try await noteService.upsert(updated)
                logger.info("Updated Core Data note with serverId=\(serverId, privacy: .private) audioPath")
            } else {
                logger.debug("No existing Note found for serverId=\(serverId, privacy: .private). Skipping Core Data update.")
            }
            return fileURL
        case .failure(let error):
            logger.error("Audio download failed: \(String(describing: error), privacy: .private)")
            if (400..<600).contains(http.statusCode) {
                // Try extract body for diagnostics
                if let data = response.resumeData, let body = String(data: data, encoding: .utf8) {
                    logger.error("Download error body: \(body, privacy: .private)")
                }
            }
            throw error
        }
    }
    
    // MARK: - PDF Downloading

    /// Returns a directory URL where PDF files are stored, creating it if needed.
    private func pdfDirectoryURL() throws -> URL {
        let dir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("PDF", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// Downloads a PDF with transcription for the given record and saves it locally. Returns file URL for further sharing.
    @discardableResult
    internal func downloadRecordPDF(recordId: Int64) async throws -> URL {

        let url = baseURL.appendingPathComponent("records/\(recordId)/pdf")

        let token = try await AuthorizationService.shared.validAccessToken()
        let headers: HTTPHeaders = [
            .authorization(bearerToken: token),
            .accept("application/pdf")
        ]

        let fileName = "record-\(recordId).pdf"
        let destinationURL: URL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName, isDirectory: false)

        let destination: DownloadRequest.Destination = { _, _ in
            return (destinationURL, [.removePreviousFile, .createIntermediateDirectories])
        }

        let download = AF.download(url, method: .get, headers: headers, to: destination)

        if let final = try? URLEncoding.default.encode(URLRequest(url: url, method: .get, headers: headers), with: nil).url?.absoluteString {
            logger.debug("PDF request URL: \(final, privacy: .private)")
        }

        let response = await download.serializingDownloadedFileURL().response

        guard let http = response.response else {
            throw ServiceError.invalidResponse
        }
        logger.debug("PDF response status: \(http.statusCode, privacy: .public)")

        switch response.result {
        case .success(let fileURL):
            logger.info("PDF saved to: \(fileURL.path(percentEncoded: false), privacy: .private)")
            return fileURL
        case .failure(let error):
            logger.error("PDF download failed: \(String(describing: error), privacy: .private)")
            if (400..<600).contains(http.statusCode) {
                if let data = response.resumeData, let body = String(data: data, encoding: .utf8) {
                    logger.error("PDF download error body: \(body, privacy: .private)")
                }
            }
            throw error
        }
    }
}
