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
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "OK", style: .plain, target: nil, action: nil)
        let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.addAnnotation(_:)))
        longPressRecogniser.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPressRecogniser)
    }
    
    override func viewDidLayoutSubviews() {
        deletePinsView.center.y += deletePinsView.frame.height
    }
    
    @IBAction func editButtonPressed(_ sender: UIBarButtonItem) {
        isEdit = !isEdit
        if isEdit {
            sender.title = "Done"
            UIView.animate(withDuration: 0.25, animations: {
                self.mapView.frame.origin.y -= self.deletePinsView.frame.height
                self.deletePinsView.center.y -= self.deletePinsView.frame.height
            })
        } else {
            sender.title = "Edit"
            UIView.animate(withDuration: 0.25, animations: {
                self.mapView.frame.origin.y += self.deletePinsView.frame.height
                self.deletePinsView.center.y += self.deletePinsView.frame.height
            })
        }
    }
    
    func addAnnotation(_ gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state != .began || isEdit {
            return
        } else {
            let touchPoint = gestureRecognizer.location(in: mapView)
            let newCoord: CLLocationCoordinate2D = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            let newAnnotation = MKPointAnnotation()
            newAnnotation.coordinate = newCoord
            createNewPinObject(newAnnotation)
            mapView.addAnnotation(newAnnotation)
        }
    }
    
    func createNewPinObject(_ annotation: MKPointAnnotation) {
        let pin = Pin(annotation: annotation, context: CoreDataStack.sharedInstance().context)
        pins.append(pin)
        CoreDataStack.sharedInstance().save()
    }
    
    func saveMapViewRegion() {
        UserDefaults.standard.set(mapView.region.center.latitude, forKey: "Latitude")
        UserDefaults.standard.set(mapView.region.center.longitude, forKey: "Longitude")
        UserDefaults.standard.set(mapView.region.span.latitudeDelta, forKey: "LatitudeDelta")
        UserDefaults.standard.set(mapView.region.span.longitudeDelta, forKey: "LongitudeDelta")
    }
    
    func loadMapViewRegion() {
        if isFirstLaunch() {
            return
        } else {
            let latitude = UserDefaults.standard.double(forKey: "Latitude")
            let longitude = UserDefaults.standard.double(forKey: "Longitude")
            let latitudeDelta = UserDefaults.standard.double(forKey: "LatitudeDelta")
            let longitudeDelta = UserDefaults.standard.double(forKey: "LongitudeDelta")
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            let region = MKCoordinateRegion(center: center, span: span)
            mapView.setRegion(region, animated: false)
        }
    }
    
    func isFirstLaunch() -> Bool {
        if let notFirstLaunch = UserDefaults.standard.value(forKey: "isFirstLaunch") {
            return notFirstLaunch as! Bool
        } else {
            UserDefaults.standard.setValue(false, forKey: "isFirstLaunch")
            return true
        }
    }
    
    func fetchPins() {
        let fetchRequest = NSFetchRequest()
        let entity = NSEntityDescription.entity(forEntityName: "Pin", in: CoreDataStack.sharedInstance().context)
        fetchRequest.entity = entity
        do {
            let foundObjects = try CoreDataStack.sharedInstance().context.fetch(fetchRequest)
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
    
    func obtainPin(_ annotation: MKAnnotation) -> Pin {
        var location: Pin!
        for pin in pins {
            if (annotation.coordinate.latitude == pin.coordinate.latitude && annotation.coordinate.longitude == pin.coordinate.longitude) {
                location = pin
                break
            }
        }
        return location
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowAlbum" {
            let albumViewController = segue.destination as! AlbumViewController
            let currentAnnotation = sender as! MKPointAnnotation
            albumViewController.currentAnnotation = currentAnnotation
            albumViewController.pin = obtainPin(currentAnnotation)
        }
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation , isEdit {
            self.mapView.removeAnnotation(annotation)
            CoreDataStack.sharedInstance().context.delete(obtainPin(annotation))
            CoreDataStack.sharedInstance().save()
        } else {
            let annotation = view.annotation
            mapView.deselectAnnotation(annotation, animated: false)
            performSegue(withIdentifier: "ShowAlbum", sender: annotation)
        }
    }
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapViewRegion()
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        } else {
            let reuseId = "pin"
            var pin = MKPinAnnotationView()
            pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pin.animatesDrop = true
            return pin
        }
    }
}

