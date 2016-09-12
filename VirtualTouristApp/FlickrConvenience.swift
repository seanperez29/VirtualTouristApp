//
//  FlickrConvenience.swift
//  VirtualTouristApp
//
//  Created by Sean Perez on 9/5/16.
//  Copyright © 2016 SeanPerez. All rights reserved.
//

import Foundation

extension FlickrClient {
    func taskForGetMethod(parameters: [String:AnyObject], completionHandler: (result: AnyObject?, errorString: String?) -> Void) -> NSURLSessionDataTask {
        let session = NSURLSession.sharedSession()
        let request = NSURLRequest(URL: flickrURLFromParameters(parameters))
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            func displayError(error: String) {
                print(error)
            }
            guard (error == nil) else {
                displayError("There was an error with your request: \(error)")
                return
            }
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx!")
                return
            }
            guard let data = data else {
                displayError("No data was returned by the request!")
                return
            }
            
            var parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                completionHandler(result: nil, errorString: "Could not parse the data as JSON: '\(data)'")
                return
            }
            
            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String where stat == Constants.FlickrResponseValues.OKStatus else {
                displayError("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                displayError("Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' in \(parsedResult)")
                return
            }
            guard let totalPages = photosDictionary["pages"] as? Int else {
                completionHandler(result: nil, errorString: "Cannot find key 'pages' in \(photosDictionary)")
                return
            }
            let pageLimit = min(totalPages, Constants.Flickr.MaxFlickrPages)
            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            self.getPhotosForPage(parameters, pageNumber: randomPage, completionHandler: completionHandler)
        }
        task.resume()
        return task
    }
    
    func getPhotosForPage(parameters: [String:AnyObject], pageNumber: Int, completionHandler: (result: AnyObject?, errorString: String?) -> Void) {
        var parametersWithPage = parameters
        parametersWithPage[Constants.FlickrParameterKeys.Page] = pageNumber
        parametersWithPage[Constants.FlickrParameterKeys.PicturesPerPage] = Constants.Flickr.FlickrPicsPerPage
        let session = NSURLSession.sharedSession()
        let request = NSURLRequest(URL: flickrURLFromParameters(parametersWithPage))
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            func displayError(error: String) {
                print(error)
            }
            guard (error == nil) else {
                displayError("There was an error with your request: \(error)")
                return
            }
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx!")
                return
            }
            guard let data = data else {
                displayError("No data was returned by the request!")
                return
            }
            
            var parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                completionHandler(result: nil, errorString: "Could not parse the data as JSON: '\(data)'")
                return
            }
            
            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String where stat == Constants.FlickrResponseValues.OKStatus else {
                displayError("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            completionHandler(result: parsedResult, errorString: nil)
        }
        task.resume()
    }
}