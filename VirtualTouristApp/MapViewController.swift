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
        loadMapViewRegion()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "OK", style: .Plain, target: nil, action: nil)
        let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.addAnnotation(_:)))
        longPressRecogniser.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressRecogniser)
    }
    
    override func viewDidLayoutSubviews() {
        deletePinsView.center.y += deletePinsView.frame.height
    }
    
    @IBAction func editButtonPressed(sender: UIBarButtonItem) {
        isEdit = !isEdit
        if isEdit {
            sender.title = "Done"
            UIView.animateWithDuration(0.25, animations: {
                self.mapView.frame.origin.y -= self.deletePinsView.frame.height
                self.deletePinsView.center.y -= self.deletePinsView.frame.height
            })
        } else {
            sender.title = "Edit"
            UIView.animateWithDuration(0.25, animations: {
                self.mapView.frame.origin.y += self.deletePinsView.frame.height
                self.deletePinsView.center.y += self.deletePinsView.frame.height
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
    
    func saveMapViewRegion() {
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.center.latitude, forKey: "Latitude")
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.center.longitude, forKey: "Longitude")
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.span.latitudeDelta, forKey: "LatitudeDelta")
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.span.longitudeDelta, forKey: "LongitudeDelta")
    }
    
    func loadMapViewRegion() {
        let latitude = NSUserDefaults.standardUserDefaults().doubleForKey("Latitude")
        let longitude = NSUserDefaults.standardUserDefaults().doubleForKey("Longitude")
        let latitudeDelta = NSUserDefaults.standardUserDefaults().doubleForKey("LatitudeDelta")
        let longitudeDelta = NSUserDefaults.standardUserDefaults().doubleForKey("LongitudeDelta")
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        let region = MKCoordinateRegion(center: center, span: span)
        mapView.setRegion(region, animated: false)
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
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapViewRegion()
    }
}



