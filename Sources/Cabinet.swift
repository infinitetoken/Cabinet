//
//  Cabinet.swift
//  Cabinet
//
//  Created by Aaron Wright on 11/6/19.
//  Copyright © 2019 Infinite Token LLC. All rights reserved.
//

import Foundation
import CoreData

public class Cabinet: NSObject {
    
    public static var shared = Cabinet()
    
    // MARK: - Properties
    
    public lazy var persistentContainer: NSPersistentContainer = {
        var container: NSPersistentContainer
            
        if self.usesCloudKit {
            container = NSPersistentCloudKitContainer(name: self.containerName)
        } else {
            container = NSPersistentContainer(name: self.containerName)
        }
        
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error: \(error)")
            }
        })
        
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        do {
            try container.viewContext.setQueryGenerationFrom(.current)
        } catch {
            fatalError("Failed to pin viewContext to the current generation: \(error)")
        }
        
        return container
    }()
    
    public var containerName: String = "Database"
    public var usesCloudKit: Bool = false
    
    // MARK: - Lifecycle
    
    public override init() {}
    
}

// MARK: - Methods

public extension Cabinet {
    
    func fetch<I>(predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor] = [], completion: @escaping (Result<[I], Error>) -> Void) where I : Storable {
        let managedObjectContext = self.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: I.entityName)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        
        let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { (asynchronousFetchResult) in
            guard let result = asynchronousFetchResult.finalResult else {
                DispatchQueue.main.async { completion(.success([])) }
                return
            }

            DispatchQueue.main.async {
                let objects = result.map({ (object) -> I? in
                    return I.from(object: object)
                }).compactMap { $0 }

                completion(.success(objects))
            }
        }

        do {
            try managedObjectContext.execute(asynchronousFetchRequest)
        } catch {
            completion(.failure(error))
        }
    }
    
    func insert<I>(object: I, completion: @escaping (Result<Bool, Error>) -> Void) where I : Storable {
        object.insert(context: self.persistentContainer.viewContext)
        
        completion(.success(true))
    }
    
    func update<I>(objects: [I], completion: @escaping (Result<Bool, Error>) -> Void) where I : Storable {
        let managedObjectContext = self.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: I.entityName)
        fetchRequest.predicate = NSPredicate(format: "id IN %@", objects.map { $0.id })
        
        let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { (asynchronousFetchResult) in
            guard let result = asynchronousFetchResult.finalResult else {
                DispatchQueue.main.async { completion(.success(false)) }
                return
            }

            DispatchQueue.main.async {
                result.forEach { object in
                    if let id = object.value(forKey: "id") as? UUID {
                        objects.first { $0.id == id }?.update(object: object)
                    }
                }
                completion(.success(true))
            }
        }

        do {
            try managedObjectContext.execute(asynchronousFetchRequest)
        } catch {
            completion(.failure(error))
        }
    }
    
    func delete<I>(objects: [I], completion: @escaping (Result<Bool, Error>) -> Void) where I : Storable {
        let managedObjectContext = self.persistentContainer.viewContext
        
        let ids = objects.map { (object) -> UUID in
            return object.id
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: I.entityName)
        fetchRequest.predicate = NSPredicate(format: "id IN %@", ids)

        let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { (asynchronousFetchResult) in
            guard let result = asynchronousFetchResult.finalResult else {
                DispatchQueue.main.async { completion(.success(false)) }
                return
            }

            DispatchQueue.main.async {
                result.forEach { object in
                    managedObjectContext.delete(object)
                }
                completion(.success(true))
            }
        }

        do {
            try managedObjectContext.execute(asynchronousFetchRequest)
        } catch {
            completion(.failure(error))
        }
    }
    
    func save(_ completion: @escaping (Result<Bool, Error>) -> Void) {
        let context = self.persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
                
                completion(.success(true))
            } catch {
                completion(.failure(error))
            }
        } else {
            completion(.success(false))
        }
    }
    
}
