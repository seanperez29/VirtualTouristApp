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
    
    func loadPhotos(latitude: Double, longitude: Double, completionHandler: (result: AnyObject?, error: String?) -> Void) {
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod, Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey, Constants.FlickrParameterKeys.BoundingBox: bboxString(latitude, pinLongitude: longitude), Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch, Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat, Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
        ]
        taskForGetMethod(methodParameters) { (result, errorString) in
            completionHandler(result: result, error: errorString)
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
    
    func getImage(imageUrl: String, completionHandler: (imageData: NSData?, error: String?)->Void) -> Void {
        let url = NSURL(string: imageUrl)!
        let request = NSURLRequest(URL: url)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                completionHandler(imageData: nil, error: error.localizedDescription)
            } else {
                completionHandler(imageData: data, error: nil)
            }
        }
        task.resume()
    }
    
    struct Caches {
        static let imageCache = ImageCache()
    }
}
