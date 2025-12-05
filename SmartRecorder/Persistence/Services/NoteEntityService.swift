//
//  NoteEntityService.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 16/11/2025.
//

import Foundation
import CoreData

// MARK: - Query options
struct NoteQuery {
    var folderId: String? = nil
    var search: String? = nil // matches title or transcription
    var serverId: String? = nil
    var cityName: String? = nil
    var streetName: String? = nil
    var hasLocation: Bool? = nil
}

struct NoteFetchOptions {
    var query: NoteQuery = .init()
    var sortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: #keyPath(NoteEntity.createdAt), ascending: false)]
    var limit: Int = 0
    var offset: Int = 0
    var includesPendingChanges: Bool = false
}

// MARK: - Service
protocol NoteEntityServicing {
    @discardableResult
    func create(_ note: Note) async throws -> Note
    func upsert(_ note: Note) async throws -> Note
    func fetch(_ options: NoteFetchOptions) async throws -> [Note]
    func count(_ query: NoteQuery) async throws -> Int
    func delete(id: UUID) async throws
    func deleteAll(inFolder folderId: String?) async throws
}

final class NoteEntityService: NoteEntityServicing {
    internal static let shared = NoteEntityService()

    private let stack: CoreDataStack

    private init(stack: CoreDataStack = .shared) {
        self.stack = stack
    }
    
    private var context: NSManagedObjectContext { stack.viewContext }

    // MARK: - Create
    @discardableResult
    func create(_ note: Note) async throws -> Note {
        try await performBackgroundSave {
            let entity = NoteEntity(context: self.context)
            entity.apply(from: note)
        }
        // Return latest version from viewContext
        if let saved = try await fetchById(note.id) { return saved }
        return note
    }

    // MARK: - Upsert
    func upsert(_ note: Note) async throws -> Note {
        try await performBackgroundSave {
            let request: NSFetchRequest<NoteEntity> = NoteEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", note.id as CVarArg)
            request.fetchLimit = 1
            if let existing = try self.context.fetch(request).first {
                existing.apply(from: note)
            } else {
                let entity = NoteEntity(context: self.context)
                entity.apply(from: note)
            }
        }
        return try await fetchById(note.id) ?? note
    }

    // MARK: - Fetch
    func fetch(_ options: NoteFetchOptions) async throws -> [Note] {
        try await withCheckedThrowingContinuation { cont in
            self.context.perform {
                do {
                    let request: NSFetchRequest<NoteEntity> = NoteEntity.fetchRequest()
                    request.predicate = Self.buildPredicate(from: options.query)
                    request.sortDescriptors = options.sortDescriptors
                    request.includesPendingChanges = options.includesPendingChanges
                    if options.limit > 0 { request.fetchLimit = options.limit }
                    if options.offset > 0 { request.fetchOffset = options.offset }
                    let objects = try self.context.fetch(request)
                    cont.resume(returning: objects.map { $0.toDomain() })
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }

    func count(_ query: NoteQuery) async throws -> Int {
        try await withCheckedThrowingContinuation { cont in
            self.context.perform {
                do {
                    let request: NSFetchRequest<NoteEntity> = NoteEntity.fetchRequest()
                    request.predicate = Self.buildPredicate(from: query)
                    let count = try self.context.count(for: request)
                    cont.resume(returning: count)
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Delete
    func delete(id: UUID) async throws {
        try await performBackgroundSave {
            let request: NSFetchRequest<NoteEntity> = NoteEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            if let obj = try self.context.fetch(request).first {
                self.context.delete(obj)
            }
        }
    }

    func deleteAll(inFolder folderId: String? = nil) async throws {
        try await withCheckedThrowingContinuation { cont in
            self.context.perform {
                do {
                    let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NoteEntity.fetchRequest()
                    fetchRequest.predicate = {
                        if let folderId { return NSPredicate(format: "folderId == %@", folderId) }
                        return nil
                    }()
                    let batch = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                    batch.resultType = .resultTypeObjectIDs
                    if let result = try self.context.execute(batch) as? NSBatchDeleteResult,
                       let objectIDs = result.result as? [NSManagedObjectID],
                       !objectIDs.isEmpty {
                        let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: objectIDs]
                        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.context])
                    }
                    cont.resume()
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Helpers
    private func fetchById(_ id: UUID) async throws -> Note? {
        try await withCheckedThrowingContinuation { cont in
            self.context.perform {
                do {
                    let request: NSFetchRequest<NoteEntity> = NoteEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                    request.fetchLimit = 1
                    cont.resume(returning: try self.context.fetch(request).first?.toDomain())
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }

    private func performBackgroundSave(_ block: @escaping () throws -> Void) async throws {
        try await withCheckedThrowingContinuation { cont in
            self.context.perform {
                do {
                    try block()
                    // Capture changed object IDs before saving
                    let inserted = self.context.insertedObjects.map { $0.objectID }
                    let updated = self.context.updatedObjects.map { $0.objectID }
                    let deleted = self.context.deletedObjects.map { $0.objectID }

                    if self.context.hasChanges { try self.context.save() }

                    // Merge changes into the viewContext so UI updates immediately
                    let changes: [AnyHashable: Any] = [
                        NSInsertedObjectsKey: inserted,
                        NSUpdatedObjectsKey: updated,
                        NSDeletedObjectsKey: deleted
                    ]
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.context])

                    cont.resume()
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }

    private static func buildPredicate(from query: NoteQuery) -> NSPredicate? {
        var predicates: [NSPredicate] = []
        if let folderId = query.folderId { predicates.append(NSPredicate(format: "folderId == %@", folderId)) }
        if let serverId = query.serverId { predicates.append(NSPredicate(format: "serverId == %@", serverId)) }
        if let hasLocation = query.hasLocation {
            if hasLocation {
                predicates.append(NSPredicate(format: "location != nil"))
            } else {
                predicates.append(NSPredicate(format: "location == nil"))
            }
        }
        if let city = query.cityName, !city.isEmpty {
            predicates.append(NSPredicate(format: "location.cityName CONTAINS[cd] %@", city))
        }
        if let street = query.streetName, !street.isEmpty {
            predicates.append(NSPredicate(format: "location.streetName CONTAINS[cd] %@", street))
        }
        if let search = query.search, !search.isEmpty {
            let like = "*\(search)*" as NSString
            let p1 = NSPredicate(format: "title LIKE[c] %@", like)
            let p2 = NSPredicate(format: "transcription LIKE[c] %@", like)
            predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: [p1, p2]))
        }
        if predicates.isEmpty { return nil }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}

