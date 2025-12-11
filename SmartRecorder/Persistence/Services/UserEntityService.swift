//
//  UserEntityService.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 28/11/2025.
//

import Foundation
import CoreData

// MARK: - Query options
struct UserQuery {
    var id: UUID? = nil
    var email: String? = nil
    var username: String? = nil
    var search: String? = nil
}

struct UserFetchOptions {
    var query: UserQuery = .init()
    var sortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: #keyPath(UserEntity.username), ascending: true)]
    var limit: Int = 0
    var offset: Int = 0
    var includesPendingChanges: Bool = false
}

// MARK: - Service protocol
protocol UserEntityServicing {
    @discardableResult
    func create(_ user: User) async throws -> User
    func upsert(_ user: User) async throws -> User
    func fetch(_ options: UserFetchOptions) async throws -> [User]
    func delete() async throws
}

final class UserEntityService: UserEntityServicing {
    private let stack: CoreDataStack

    init(stack: CoreDataStack = .shared) {
        self.stack = stack
    }

    // MARK: - Create
    @discardableResult
    func create(_ user: User) async throws -> User {
        try await performBackgroundSave { context in
            let entity = UserEntity(context: context)
            entity.apply(from: user)
        }
        return try await fetchById(user.id) ?? user
    }

    // MARK: - Upsert
    func upsert(_ user: User) async throws -> User {
        try await performBackgroundSave { context in
            let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", user.id as CVarArg)
            request.fetchLimit = 1
            if let existing = try context.fetch(request).first {
                existing.apply(from: user)
            } else {
                let entity = UserEntity(context: context)
                entity.apply(from: user)
            }
        }
        return try await fetchById(user.id) ?? user
    }

    // MARK: - Fetch
    func fetch(_ options: UserFetchOptions) async throws -> [User] {
        try await withCheckedThrowingContinuation { cont in
            let context = stack.viewContext
            context.perform {
                do {
                    let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
                    request.predicate = Self.buildPredicate(from: options.query)
                    request.sortDescriptors = options.sortDescriptors
                    request.includesPendingChanges = options.includesPendingChanges
                    if options.limit > 0 { request.fetchLimit = options.limit }
                    if options.offset > 0 { request.fetchOffset = options.offset }
                    let objects = try context.fetch(request)
                    cont.resume(returning: objects.map { $0.toDomain() })
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Single-user conveniences
    /// Returns the only stored user (if any). Since the app has only one user, we fetch the first one.
    func current() async throws -> User? {
        try await withCheckedThrowingContinuation { cont in
            let context = stack.viewContext
            context.perform {
                do {
                    let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
                    request.fetchLimit = 1
                    let obj = try context.fetch(request).first
                    cont.resume(returning: obj?.toDomain())
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }

    /// Replaces the current user with the provided one (deletes others if present).
    @discardableResult
    func replaceCurrent(with user: User) async throws -> User {
        try await delete()
        return try await create(user)
    }

    func delete() async throws {
        try await withCheckedThrowingContinuation { cont in
            let context = stack.viewContext
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<NSFetchRequestResult> = UserEntity.fetchRequest()
                    let batch = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                    batch.resultType = .resultTypeObjectIDs
                    if let result = try context.execute(batch) as? NSBatchDeleteResult,
                       let objectIDs = result.result as? [NSManagedObjectID],
                       !objectIDs.isEmpty {
                        let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: objectIDs]
                        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.stack.viewContext])
                    }
                    cont.resume()
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Helpers
    private func fetchById(_ id: UUID) async throws -> User? {
        try await withCheckedThrowingContinuation { cont in
            let context = stack.viewContext
            context.perform {
                do {
                    let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                    request.fetchLimit = 1
                    cont.resume(returning: try context.fetch(request).first?.toDomain())
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }

    private func performBackgroundSave(_ block: @escaping (NSManagedObjectContext) throws -> Void) async throws {
        try await withCheckedThrowingContinuation { cont in
            let context = stack.viewContext
            context.perform {
                do {
                    try block(context)
                    if context.hasChanges { try context.save() }
                    cont.resume()
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }

    private static func buildPredicate(from query: UserQuery) -> NSPredicate? {
        var predicates: [NSPredicate] = []
        if let id = query.id { predicates.append(NSPredicate(format: "id == %@", id as CVarArg)) }
        if let email = query.email, !email.isEmpty {
            predicates.append(NSPredicate(format: "email ==[c] %@", email))
        }
        if let username = query.username, !username.isEmpty {
            predicates.append(NSPredicate(format: "username ==[c] %@", username))
        }
        if let search = query.search, !search.isEmpty {
            let like = "*\(search)*" as NSString
            let p1 = NSPredicate(format: "firstName LIKE[c] %@", like)
            let p2 = NSPredicate(format: "lastName LIKE[c] %@", like)
            let p3 = NSPredicate(format: "username LIKE[c] %@", like)
            let p4 = NSPredicate(format: "email LIKE[c] %@", like)
            predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: [p1, p2, p3, p4]))
        }
        if predicates.isEmpty { return nil }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}
