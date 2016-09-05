//
//  ImageCache.swift
//  VirtualTouristApp
//
//  Created by Sean Perez on 9/5/16.
//  Copyright © 2016 SeanPerez. All rights reserved.
//

import Foundation
import UIKit

class ImageCache {
        
    private var inMemoryCache = NSCache()
    
    func imageWithPath(path: String) -> UIImage? {
        if let image = inMemoryCache.objectForKey(path) as? UIImage {
            return image
        }
        if let data = NSData(contentsOfFile: path) {
            return UIImage(data: data)
        }
        return nil
        }
        
    func storeImage(image: UIImage?, withPath path: String) {
        if image == nil {
            inMemoryCache.removeObjectForKey(path)
            do {
                try NSFileManager.defaultManager().removeItemAtPath(path)
            } catch _ {}
            return
            }
            inMemoryCache.setObject(image!, forKey: path)
            let data = UIImagePNGRepresentation(image!)!
            data.writeToFile(path, atomically: true)
    }
}