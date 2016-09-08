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

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String:AnyObject], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        id = dictionary["id"] as! String
        imageUrl = dictionary["url_m"] as! String
        filePath = pathForIdentifier(id)
    }
    
    static func photosFromResult(result: AnyObject, context: NSManagedObjectContext) -> [Photo] {
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
    
    func pathForIdentifier(identifier: String) -> String {
        let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(identifier)
        
        return fullURL.path!
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
