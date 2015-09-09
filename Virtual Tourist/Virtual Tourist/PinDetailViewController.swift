//
//  PinDetailViewController.swift
//  Virtual Turist
//
//  Created by Kinan Turjman on 7/22/15.
//  Copyright (c) 2015 Kinan Turman. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class PinDetailViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, NSFetchedResultsControllerDelegate, MKMapViewDelegate {
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var selectedIndexes = [NSIndexPath]()
    var insertedIndexPaths = [NSIndexPath]()
    var deletedIndexPaths = [NSIndexPath]()
    var updatedIndexPaths = [NSIndexPath]()
    
    @IBOutlet weak var collectionView: UICollectionView?
    @IBOutlet weak var bottomButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    
    var noImagesLabel: UILabel!
    
    var pin: Pin!
    
    var downloadTaskInProgress = false
    
    var deleteAllPressed = false
    
    var allowsSelection = false
    
    // MARK: - Core Data Convenience
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set map view
        mapView.delegate = self
        mapView.userInteractionEnabled = false
        
        let location = CLLocationCoordinate2DMake(pin.latitude, pin.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
        
        // add pin
        let annotation = VTAnnotation(coordinate: location)
        mapView.addAnnotation(annotation)
        
        collectionView!.backgroundColor = UIColor.whiteColor()
        collectionView!.allowsMultipleSelection = true
        
        self.view.addSubview(collectionView!)
        
        noImagesLabel = UILabel(frame: CGRectMake(0, 0, 200, 20))
        var rect = self.collectionView!.frame
        noImagesLabel.center = CGPointMake(rect.width/4, rect.height/2)
        noImagesLabel.textAlignment = NSTextAlignment.Center
        noImagesLabel.text = "This pin has no images."
        noImagesLabel.hidden = true
        self.collectionView?.addSubview(noImagesLabel)
        
        bottomButton.enabled = false
        
        // Step 2: Perform the fetch
        fetchedResultsController.performFetch(nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        Flickr.sharedInstance().fetchImagesForPin(pin, completionHandler: { (success) -> Void in
            
        })
        
        updateBottomButton()
        
    }
    
    override func viewDidLayoutSubviews() {

        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        
        let width = floor(self.collectionView!.frame.size.width/3.5)
        layout.itemSize = CGSize(width: width, height: width)
        collectionView!.collectionViewLayout = layout
    }
    
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        let pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "myPin")
        pinAnnotationView.canShowCallout = false
        pinAnnotationView.image = UIImage(named:"pin2")
        return pinAnnotationView
    }
    
    // Mark: - Fetched Results Controller
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin);
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
        
    }()

    func fetchCollection(){
        
        downloadTaskInProgress = true
        
        Flickr.sharedInstance().downloadImagePathsForPin(pin, completionHandler: { (hasNoImages) -> Void in
            if hasNoImages {
                dispatch_async(dispatch_get_main_queue()){
                    self.noImagesLabel.hidden = false
                    self.updateBottomButton()
                }
            } else {
                Flickr.sharedInstance().fetchImagesForPin(self.pin, completionHandler: { (success) -> Void in
                })
            }
            self.downloadTaskInProgress = false
        })
    }
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionViewCell", forIndexPath: indexPath) as! CustomCollectionViewCell
        
        configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! CustomCollectionViewCell
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        if allowsSelection {
            
            selectedIndexes.append(indexPath)
        
            // Then reconfigure the cell
            configureCell(cell, atIndexPath: indexPath)
        
            updateBottomButton()
        }
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! CustomCollectionViewCell
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        if allowsSelection {
            if let index = find(selectedIndexes, indexPath) {
                selectedIndexes.removeAtIndex(index)
            }
        
            configureCell(cell, atIndexPath: indexPath)
        
            // update button when a cell is selected
            updateBottomButton()
        }
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()

    }
    
    // The second method may be called multiple times, once for each Color object that is added, deleted, or changed.
    // We store the incex paths into the three arrays.
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type{
            
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
            println("Move an item. We don't expect to see this in this app.")
            break
        default:
            break
        }
    }
    
    // This method is invoked after all of the changed in the current batch have been collected
    // into the three index path arrays (insert, delete, and upate). We now need to loop through the
    // arrays and perform the changes.
    //
    // The most interesting thing about the method is the collection view's "performBatchUpdates" method.
    // Notice that all of the changes are performed inside a closure that is handed to the collection view.
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        dispatch_async(dispatch_get_main_queue()){
            self.collectionView!.performBatchUpdates({() -> Void in
                
                for indexPath in self.insertedIndexPaths {
                    self.collectionView!.insertItemsAtIndexPaths([indexPath])
                }
                for indexPath in self.deletedIndexPaths {
                    self.collectionView!.deleteItemsAtIndexPaths([indexPath])
                }
                for indexPath in self.updatedIndexPaths {
                    self.collectionView!.reloadItemsAtIndexPaths([indexPath])
                }
                if self.pin.photos.count == 0 && self.deleteAllPressed {
                    self.fetchCollection()
                    self.deleteAllPressed = false
                }
                
                self.updateBottomButton()
                
            }, completion: nil)
        }
    }
    
    func configureCell(cell: CustomCollectionViewCell, atIndexPath indexPath: NSIndexPath){
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        cell.image!.image = nil
        
        if let index = find(selectedIndexes, indexPath) {
            cell.image!.alpha = 0.35
        } else {
            cell.image!.alpha = 1.0
        }
        
        var posterImage = UIImage(named: "imgPlaceholder")
        
        if photo.image != nil {
            posterImage = photo.image
            cell.activityIndicator.hidden = true
        }
        else {
            cell.activityIndicator.startAnimating()
            cell.activityIndicator.hidden = false
        }
        
        cell.image!.image = posterImage
    }
    
    @IBAction func buttonButtonClicked() {
        
        if selectedIndexes.isEmpty {
            bottomButton.enabled = false
            
            if pin.photos.count == 0 {
                fetchCollection()
            } else {
                deleteAllColors()
            }
        } else {
            deleteSelectedColors()
        }
    }
    
    func deleteAllColors() {
        
        for photo in fetchedResultsController.fetchedObjects as! [Photo] {
            photo.image = nil
            sharedContext.deleteObject(photo)
        }
        
        deleteAllPressed = true
        saveContext()
    }
    
    func deleteSelectedColors() {
        var colorsToDelete = [Photo]()
        
        for indexPath in selectedIndexes {
            colorsToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
        }
        
        for photo in colorsToDelete {
            photo.image = nil
            sharedContext.deleteObject(photo)
        }
        
        selectedIndexes = [NSIndexPath]()
        
        saveContext()
    }
    
    func updateBottomButton() {
        // case 1: there are no photos
        if pin.photos.count == 0 && !downloadTaskInProgress {
            self.bottomButton.enabled = true
        } else if downloadTaskInProgress {
            self.bottomButton.enabled = false
        } else {
            // case 2: all images have been loaded
            self.bottomButton.enabled = self.allImagesLoaded()
        }
        
        if selectedIndexes.count > 0 {
            bottomButton.setTitle("Delete Selected", forState: UIControlState.Normal)
        } else {
            bottomButton.setTitle("New Collection", forState: UIControlState.Normal)
        }
    }
    
    func allImagesLoaded() -> Bool {
        if pin.allPhotosDownloaded() {
            allowsSelection = true
            return true
        } else {
            return false
        }
    }
}