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
        
    fileprivate var inMemoryCache = NSCache<NSString, AnyObject>()
    
    func imageWithPath(_ path: String) -> UIImage? {
        if let image = inMemoryCache.object(forKey: path as NSString) as? UIImage {
            return image
        }
        if let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            return UIImage(data: data)
        }
        return nil
        }
        
    func storeImage(_ image: UIImage?, withPath path: String) {
        if image == nil {
            inMemoryCache.removeObject(forKey: path as NSString)
            
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch _ {}
            return
            }
            inMemoryCache.setObject(image!, forKey: path as NSString)
            let data = UIImagePNGRepresentation(image!)!
            try? data.write(to: URL(fileURLWithPath: path), options: [.atomic])
    }
}
