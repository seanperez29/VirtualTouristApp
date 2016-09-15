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

@available(iOS 10.0, *)
class AlbumViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var noImagesLabel: UILabel!
    var currentAnnotation: MKPointAnnotation!
    var pin: Pin!
    var selectedIndexes = [IndexPath]()
    var insertedIndexPaths: [IndexPath]!
    var deletedIndexPaths: [IndexPath]!
    var updatedIndexPaths: [IndexPath]!
    lazy var fetchedResultsController: NSFetchedResultsController<Photo> = {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Photo.fetchRequest()
        let entity = NSEntityDescription.entity(forEntityName: "Photo", in: CoreDataStack.sharedInstance().context)
        fetchRequest.entity = entity
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
        let _fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.sharedInstance().context, sectionNameKeyPath: nil, cacheName: nil)
        _fetchedResultsController.delegate = self
        return _fetchedResultsController as! NSFetchedResultsController<Photo>
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setMapViewAnnotationAndRegion(currentAnnotation.coordinate)
        loadPhotos(pin)
        performFetch()
        if pin.hasPhotos {
            newCollectionButton.isEnabled = true
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
            photosToDelete.append(fetchedResultsController.object(at: indexPath))
        }
        for photo in photosToDelete {
            CoreDataStack.sharedInstance().context.delete(photo)
        }
        CoreDataStack.sharedInstance().save()
        selectedIndexes = [IndexPath]()
    }
    
    func deleteAllPhotos() {
        if fetchedResultsController.fetchedObjects != nil {
            for photo in fetchedResultsController.fetchedObjects! as [Photo] {
                CoreDataStack.sharedInstance().context.delete(photo)
            }
        }
        CoreDataStack.sharedInstance().save()
    }
    
    func setMapViewAnnotationAndRegion(_ location: CLLocationCoordinate2D) {
        let span = MKCoordinateSpanMake(0.07, 0.07)
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: false)
        mapView.addAnnotation(currentAnnotation)
    }
    
    func loadPhotos(_ pin: Pin) {
        newCollectionButton.isEnabled = false
        if pin.photo.isEmpty {
            FlickrClient.sharedInstance.loadPhotos(pin) { hasPhotos, errorString in
                guard (errorString == nil) else {
                    self.showAlert("There was an error loading the images")
                    return
                }
                performUIUpdatesOnMain({
                    if hasPhotos == false {
                        self.noImagesLabel.isHidden = false
                    }
                    self.newCollectionButton.isEnabled = true
                })
            }
        }
    }

    func updateNewCollectionButton() {
        if selectedIndexes.count > 0 {
            newCollectionButton.setTitle("Remove Selected Photos", for: UIControlState())
        } else {
            newCollectionButton.setTitle("New Collection", for: UIControlState())
        }
    }
    
    func showAlert(_ error: String) {
        performUIUpdatesOnMain { 
            let alert = UIAlertController(title: error, message: "Press OK to Dismiss", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    deinit {
        fetchedResultsController.delegate = nil
    }
    
}

@available(iOS 10.0, *)
extension AlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        if (sectionInfo.numberOfObjects == 0) && pin.hasPhotos {
            loadPhotos(pin)
        }
        return sectionInfo.numberOfObjects
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCollectionViewCell
        let photo = fetchedResultsController.object(at: indexPath)
        cell.configureCell(photo)
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoCollectionViewCell
        if let index = selectedIndexes.index(of: indexPath) {
            selectedIndexes.remove(at: index)
            cell.imageView.alpha = 1
        } else {
            selectedIndexes.append(indexPath)
            cell.imageView.alpha = 0.5
        }
        updateNewCollectionButton()
        
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width/3, height: collectionView.bounds.size.width/3)
    }
}

@available(iOS 10.0, *)
extension AlbumViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexPaths = [IndexPath]()
        deletedIndexPaths = [IndexPath]()
        updatedIndexPaths = [IndexPath]()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .delete:
            deletedIndexPaths.append(indexPath!)
            break
        case .update:
            updatedIndexPaths.append(indexPath!)
            break
        case .move:
            print("Move an item")
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        DispatchQueue.main.async {
            self.collectionView.performBatchUpdates(
                {
                    () -> Void in
                    for indexPath in self.insertedIndexPaths {
                        self.collectionView.insertItems(at: [indexPath])
                    }
                    for indexPath in self.deletedIndexPaths {
                        self.collectionView.deleteItems(at: [indexPath])
                    }
                    for indexPath in self.updatedIndexPaths {
                        self.collectionView.reloadItems(at: [indexPath])
                    }
                }
                ,completion: nil)
        }
    }
}










