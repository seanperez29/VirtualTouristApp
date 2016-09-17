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
    
    func loadPhotos(_ pin: Pin, completionHandler: @escaping (_ hasPhotos: Bool?, _ errorString: String?) -> Void) {
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod, Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey, Constants.FlickrParameterKeys.BoundingBox: bboxString(pin.latitude, pinLongitude: pin.longitude), Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch, Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat, Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
        ]
        taskForGetMethod(methodParameters as [String : AnyObject]) { (result, errorString) in
            guard (errorString == nil) else {
                print("There was an error: \(errorString)")
                completionHandler(nil, errorString)
                return
            }
            let photos = Photo.photosFromResult(result!, context: CoreDataStack.sharedInstance().context)
            for photo in photos {
                photo.pin = pin
            }
            if photos.isEmpty {
                completionHandler(false, nil)
            }
            pin.hasPhotos = true
            completionHandler(true, nil)
            CoreDataStack.sharedInstance().save()
        }
    }
    
    func bboxString(_ pinLatitude: Double, pinLongitude: Double) -> String {
        let minimumLon = max(Double(pinLongitude) - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        let minimumLat = max(Double(pinLatitude) - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
        let maximumLon = min(Double(pinLongitude) + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        let maximumLat = min(Double(pinLatitude) + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    func flickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        return components.url!
    }
    
    func getImage(_ imageUrl: String, completionHandler: @escaping (_ imageData: Data?, _ errorString: String?) -> Void) -> URLSessionDataTask {
        let url = URL(string: imageUrl)
        let request = URLRequest(url: url!)
            let session = URLSession.shared
            let task = session.dataTask(with: request, completionHandler: {data, response, error in
                if let error = error {
                    completionHandler(nil, error.localizedDescription)
                } else {
                    completionHandler(data, nil)
                }
            }) 
        task.resume()
        return task
    }
    
}
