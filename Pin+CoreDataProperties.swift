//
//  Pin+CoreDataProperties.swift
//  VirtualTouristApp
//
//  Created by Sean Perez on 9/4/16.
//  Copyright © 2016 SeanPerez. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Pin {

    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var hasPhotos: Bool
    @NSManaged var photo: [Photo]

}
