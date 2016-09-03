//
//  MapViewController.swift
//  VirtualTouristApp
//
//  Created by Sean Perez on 8/31/16.
//  Copyright © 2016 SeanPerez. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deletePinsView: UIView!
    var isEdit = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "OK", style: .Plain, target: nil, action: nil)
        
        let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.addAnnotation(_:)))
        longPressRecogniser.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressRecogniser)
    }
    
    override func viewDidLayoutSubviews() {
        deletePinsView.center.y += 100
    }
    
    @IBAction func editButtonPressed(sender: UIBarButtonItem) {
        isEdit = !isEdit
        if isEdit {
            sender.title = "Done"
            UIView.animateWithDuration(0.25, animations: {
                self.mapView.frame.origin.y -= self.deletePinsView.frame.height
                self.deletePinsView.center.y -= 100
            })
        } else {
            sender.title = "Edit"
            UIView.animateWithDuration(0.25, animations: {
                self.mapView.frame.origin.y += self.deletePinsView.frame.height
                self.deletePinsView.center.y += 100
            })
        }
    }
    
    func addAnnotation(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state != .Began {
            return
        } else {
            let touchPoint = gestureRecognizer.locationInView(mapView)
            let newCoord: CLLocationCoordinate2D = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            let newAnnotation = MKPointAnnotation()
            newAnnotation.coordinate = newCoord
            mapView.addAnnotation(newAnnotation)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowAlbum" {
            let albumViewController = segue.destinationViewController as! AlbumViewController
            let currentAnnotation = sender as! MKPointAnnotation
            albumViewController.currentAnnotation = currentAnnotation
        }
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if let annotation = view.annotation where isEdit {
            self.mapView.removeAnnotation(annotation)
        } else {
            let annotation = view.annotation
            performSegueWithIdentifier("ShowAlbum", sender: annotation)
        }
    }
}



