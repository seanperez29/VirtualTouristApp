//
//  AlbumViewController.swift
//  VirtualTouristApp
//
//  Created by Sean Perez on 9/1/16.
//  Copyright © 2016 SeanPerez. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class AlbumViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var noImagesLabel: UILabel!
    var currentAnnotation: MKPointAnnotation!
    var pin: Pin!
    var selectedIndexes = [NSIndexPath]()
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest()
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: CoreDataStack.sharedInstance().context)
        fetchRequest.entity = entity
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.sharedInstance().context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setMapViewAnnotationAndRegion(currentAnnotation.coordinate)
        loadPhotos(pin)
        performFetch()
        if pin.hasPhotos {
            newCollectionButton.enabled = true
        }
    }
    
    func performFetch() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Could not fetch photos")
        }
    }
    
    @IBAction func newCollectionButtonPressed() {
        if selectedIndexes.count > 0 {
            deleteSelectedItems()
            updateNewCollectionButton()
        } else {
            deleteAllPhotos()
            updateNewCollectionButton()
        }
    }
    
    func deleteSelectedItems() {
        var photosToDelete = [Photo]()
        for indexPath in selectedIndexes {
            photosToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
        }
        for photo in photosToDelete {
            CoreDataStack.sharedInstance().context.deleteObject(photo)
        }
        CoreDataStack.sharedInstance().save()
        selectedIndexes = [NSIndexPath]()
    }
    
    func deleteAllPhotos() {
        for photo in fetchedResultsController.fetchedObjects as! [Photo] {
            CoreDataStack.sharedInstance().context.deleteObject(photo)
        }
        CoreDataStack.sharedInstance().save()
    }
    
    func setMapViewAnnotationAndRegion(location: CLLocationCoordinate2D) {
        let span = MKCoordinateSpanMake(0.07, 0.07)
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: false)
        mapView.addAnnotation(currentAnnotation)
    }
    
    func loadPhotos(pin: Pin) {
        newCollectionButton.enabled = false
        if pin.photo.isEmpty {
            FlickrClient.sharedInstance.loadPhotos(pin) { hasPhotos, errorString in
                guard (errorString == nil) else {
                    self.showAlert("There was an error loading the images")
                    return
                }
                performUIUpdatesOnMain({
                    if hasPhotos == false {
                        self.noImagesLabel.hidden = false
                    }
                    self.newCollectionButton.enabled = true
                })
            }
        }
    }

    func updateNewCollectionButton() {
        if selectedIndexes.count > 0 {
            newCollectionButton.setTitle("Remove Selected Photos", forState: .Normal)
        } else {
            newCollectionButton.setTitle("New Collection", forState: .Normal)
        }
    }
    
    func showAlert(error: String) {
        performUIUpdatesOnMain { 
            let alert = UIAlertController(title: error, message: "Press OK to Dismiss", preferredStyle: .Alert)
            let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alert.addAction(action)
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    deinit {
        fetchedResultsController.delegate = nil
    }
    
}

extension AlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        if (sectionInfo.numberOfObjects == 0) && pin.hasPhotos {
            loadPhotos(pin)
        }
        return sectionInfo.numberOfObjects
    }
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        cell.imageView.alpha = 1
        cell.configureCell(photo)
        return cell
    }
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        if let index = selectedIndexes.indexOf(indexPath) {
            selectedIndexes.removeAtIndex(index)
            cell.imageView.alpha = 1
        } else {
            selectedIndexes.append(indexPath)
            cell.imageView.alpha = 0.5
        }
        updateNewCollectionButton()
        
    }
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width/3, height: collectionView.bounds.size.width/3)
    }
}

extension AlbumViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type {
        case .Insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            updatedIndexPaths.append(indexPath!)
            break
        case .Move:
            print("Move an item")
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        dispatch_async(dispatch_get_main_queue()) {
            self.collectionView.performBatchUpdates(
                {
                    () -> Void in
                    for indexPath in self.insertedIndexPaths {
                        self.collectionView.insertItemsAtIndexPaths([indexPath])
                    }
                    for indexPath in self.deletedIndexPaths {
                        self.collectionView.deleteItemsAtIndexPaths([indexPath])
                    }
                    for indexPath in self.updatedIndexPaths {
                        self.collectionView.reloadItemsAtIndexPaths([indexPath])
                    }
                }
                ,completion: nil)
        }
    }
}










