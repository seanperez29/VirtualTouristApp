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
            activityIndicator.hidden = true
            imageView.image = photo.photoImage
        } else {
            imageView.image = UIImage(named: "Placeholder")
            activityIndicator.hidden = false
            activityIndicator.startAnimating()
            FlickrClient.sharedInstance.getImage(photo.imageUrl, completionHandler: { (imageData, errorString) in
                guard (errorString == nil) else {
                    print("Error downloading image: \(errorString)")
                    return
                }
                if let image = UIImage(data: imageData!) {
                    performUIUpdatesOnMain({
                        self.imageView.image = image
                        self.activityIndicator.stopAnimating()
                        self.activityIndicator.hidden = true
                        photo.photoImage = image
                    })
                }
            })
        }
    }
}