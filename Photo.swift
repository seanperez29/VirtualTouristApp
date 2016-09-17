//
//  Photo.swift
//  VirtualTouristApp
//
//  Created by Sean Perez on 9/4/16.
//  Copyright © 2016 SeanPerez. All rights reserved.
//

import Foundation
import CoreData
import UIKit


class Photo: NSManagedObject {

    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    init(dictionary: [String:AnyObject], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "Photo", in: context)!
        super.init(entity: entity, insertInto: context)
        id = dictionary["id"] as! String
        imageUrl = dictionary["url_m"] as! String
        filePath = pathForIdentifier(id)
    }
    
    static func photosFromResult(_ result: AnyObject, context: NSManagedObjectContext) -> [Photo] {
        var photos = [Photo]()
        if let photosResult = result["photos"] as? NSDictionary {
            if let photosArray = photosResult["photo"] as? [[String:AnyObject]] {
                for dict in photosArray {
                    let photo = Photo(dictionary: dict, context: context)
                    photos.append(photo)
                }
            }
        }
        return photos
    }
    
    func pathForIdentifier(_ identifier: String) -> String {
        let documentsDirectory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fullPath = documentsDirectory.appendingPathComponent(identifier)
        return fullPath.path
    }
    
    var photoImage: UIImage? {
        get {
            return FlickrClient.Caches.imageCache.imageWithPath(filePath)
        }
        set {
            FlickrClient.Caches.imageCache.storeImage(newValue, withPath: filePath)
        }
    }
    
    override func prepareForDeletion() {
        FlickrClient.Caches.imageCache.storeImage(nil, withPath: filePath)
    }

}
