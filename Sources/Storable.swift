//
//  Storable.swift
//  Storable
//
//  Created by Aaron Wright on 11/6/19.
//  Copyright © 2019 Infinite Token LLC. All rights reserved.
//

import Foundation
import CoreData

public protocol Storable: Identifiable {
    
    static var entityName: String { get }
    
    var id: UUID { get set }
    
    static func from(object: NSManagedObject) -> Self?
    
    func insert(context: NSManagedObjectContext)
    func update(object: NSManagedObject)
    
}
