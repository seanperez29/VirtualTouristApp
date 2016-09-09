//
//  MapViewController.swift
//  VirtualTouristApp
//
//  Created by Sean Perez on 8/31/16.
//  Copyright © 2016 SeanPerez. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deletePinsView: UIView!
    var isEdit = false
    var pins = [Pin]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchPins()
        placePinsOnMap()
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
            createNewPinObject(newAnnotation)
            mapView.addAnnotation(newAnnotation)
        }
    }
    
    func createNewPinObject(annotation: MKPointAnnotation) {
        let pin = Pin(annotation: annotation, context: CoreDataStack.sharedInstance().context)
        pins.append(pin)
        CoreDataStack.sharedInstance().save()
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
    
    func fetchPins() {
        let fetchRequest = NSFetchRequest()
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: CoreDataStack.sharedInstance().context)
        fetchRequest.entity = entity
        do {
            let foundObjects = try CoreDataStack.sharedInstance().context.executeFetchRequest(fetchRequest)
            pins = foundObjects as! [Pin]
        } catch {
            fatalError("Could not fetch pins")
        }
    }
    
    func placePinsOnMap() {
        for pin in pins {
            let annotation = MKPointAnnotation()
            annotation.coordinate = pin.coordinate
            mapView.addAnnotation(annotation)
        }
    }
    
    func obtainPin(annotation: MKAnnotation) -> Pin {
        var location: Pin!
        for pin in pins {
            if (annotation.coordinate.latitude == pin.coordinate.latitude && annotation.coordinate.longitude == pin.coordinate.longitude) {
                location = pin
                break
            }
        }
        return location
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowAlbum" {
            let albumViewController = segue.destinationViewController as! AlbumViewController
            let currentAnnotation = sender as! MKPointAnnotation
            albumViewController.currentAnnotation = currentAnnotation
            //albumViewController.managedObjectContext = managedObjectContext
            albumViewController.pin = obtainPin(currentAnnotation)
        }
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if let annotation = view.annotation where isEdit {
            self.mapView.removeAnnotation(annotation)
            CoreDataStack.sharedInstance().context.deleteObject(obtainPin(annotation))
            CoreDataStack.sharedInstance().save()
        } else {
            let annotation = view.annotation
            mapView.deselectAnnotation(annotation, animated: false)
            performSegueWithIdentifier("ShowAlbum", sender: annotation)
        }
    }
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapViewRegion()
    }
}



