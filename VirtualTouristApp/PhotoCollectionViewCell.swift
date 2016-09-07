//
//  PhotoCollectionViewCell.swift
//  VirtualTouristApp
//
//  Created by Sean Perez on 9/1/16.
//  Copyright © 2016 SeanPerez. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    func configureCell(photo: Photo) {
        if photo.photoImage != nil {
            imageView.hidden = false
            imageView.image = photo.photoImage
        } else {
            activityIndicator.startAnimating()
            imageView.image = UIImage(named: "Placeholder")
            FlickrClient.sharedInstance.getImage(photo.imageUrl, completionHandler: { (imageData, error) in
                if error != nil {
                    print("Error downloading image: \(error)")
                } else {
                    if let image = UIImage(data: imageData!) {
                        dispatch_async(dispatch_get_main_queue(), { 
                            self.imageView.hidden = false
                            self.imageView.image = image
                            self.activityIndicator.stopAnimating()
                            self.activityIndicator.hidden = true
                            photo.photoImage = image
                        })
                    }
                }
            })
        }
        
    }
    

}