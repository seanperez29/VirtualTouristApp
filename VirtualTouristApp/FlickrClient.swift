//
//  FlickrClient.swift
//  VirtualTouristApp
//
//  Created by Sean Perez on 9/5/16.
//  Copyright © 2016 SeanPerez. All rights reserved.
//

import Foundation

class FlickrClient: NSObject {
    static let sharedInstance = FlickrClient()
    
    func loadPhotos(pin: Pin, completionHandler: (hasPhotos: Bool?, errorString: String?) -> Void) {
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod, Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey, Constants.FlickrParameterKeys.BoundingBox: bboxString(pin.latitude, pinLongitude: pin.longitude), Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch, Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat, Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
        ]
        taskForGetMethod(methodParameters) { (result, errorString) in
            guard (errorString == nil) else {
                print("There was an error: \(errorString)")
                completionHandler(hasPhotos: nil, errorString: errorString)
                return
            }
            let photos = Photo.photosFromResult(result!, context: CoreDataStack.sharedInstance().context)
            for photo in photos {
                photo.pin = pin
            }
            if photos.isEmpty {
                completionHandler(hasPhotos: false, errorString: nil)
            }
            pin.hasPhotos = true
            completionHandler(hasPhotos: true, errorString: nil)
            CoreDataStack.sharedInstance().save()
        }
    }
    
    func bboxString(pinLatitude: Double, pinLongitude: Double) -> String {
        let minimumLon = max(Double(pinLongitude) - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        let minimumLat = max(Double(pinLatitude) - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
        let maximumLon = min(Double(pinLongitude) + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        let maximumLat = min(Double(pinLatitude) + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    func flickrURLFromParameters(parameters: [String:AnyObject]) -> NSURL {
        let components = NSURLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [NSURLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        return components.URL!
    }
    
    func getImage(imageUrl: String, completionHandler: (imageData: NSData?, errorString: String?)->Void) -> Void {
        let url = NSURL(string: imageUrl)!
        let request = NSURLRequest(URL: url)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                completionHandler(imageData: nil, errorString: error.localizedDescription)
            } else {
                completionHandler(imageData: data, errorString: nil)
            }
        }
        task.resume()
    }
    
    struct Caches {
        static let imageCache = ImageCache()
    }
}
