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

/* This class handles the pin detail view controller to show the photo collection for a pin */

class PinDetailViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, NSFetchedResultsControllerDelegate, MKMapViewDelegate {
    
    
    // MARK: IBOutlets properties
    @IBOutlet weak var collectionView: UICollectionView? // the collection view
    @IBOutlet weak var bottomButton: UIButton! // the button at the bottom of the view
    @IBOutlet weak var mapView: MKMapView! // the mapview at the top of the view
    
    // MARK: Other properties
    // Arrays to keep track of insertions, deletions, and updates when using Fetched Results Controller
    var selectedIndexes = [NSIndexPath]()
    var insertedIndexPaths = [NSIndexPath]()
    var deletedIndexPaths = [NSIndexPath]()
    var updatedIndexPaths = [NSIndexPath]()
    
    var noPhotosLabel: UILabel! // label to display if pin has no photos
    var pin: Pin! // the pin
    
    // flag to keep track of download task in progress
    var downloadTaskInProgress = false
    
    // flag to use when new collection is pressed
    var deleteAllPressed = false
    
    // flag to be used to allow the selection of photos to remove
    var allowsSelection = false
    
    // MARK: - Core Data Convenience
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    // MARK: View Functions
    
    /* viewDidLoad */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set map view
        mapView.delegate = self
        mapView.userInteractionEnabled = false
        
        // set the region
        let location = CLLocationCoordinate2DMake(pin.latitude, pin.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
        
        // add the pin
        let annotation = VTAnnotation(coordinate: location)
        mapView.addAnnotation(annotation)
        
        // set properties for the collection view
        collectionView!.backgroundColor = UIColor.whiteColor()
        collectionView!.allowsMultipleSelection = true
        
        // add the collection view
        self.view.addSubview(collectionView!)
        
        // create the no photos label
        noPhotosLabel = UILabel(frame: CGRectMake(0, 0, 200, 20))
        var rect = self.collectionView!.frame
        noPhotosLabel.center = CGPointMake(rect.width/4, rect.height/2)
        noPhotosLabel.textAlignment = NSTextAlignment.Center
        noPhotosLabel.text = "This pin has no images."
        noPhotosLabel.hidden = true
        
        // add it to the collection view
        self.collectionView?.addSubview(noPhotosLabel)
        
        // disable the bottom button
        bottomButton.enabled = false
        
        // perform the fetch
        fetchedResultsController.performFetch(nil)
    }
    
     /* viewDidAppear */
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // whenever the view appears, start fetching the pin's images
        Flickr.sharedInstance().fetchImagesForPin(pin, completionHandler: { (success) -> Void in
            
        })
        
        // update the bottom button
        updateBottomButton()
        
    }
    
     /* viewDidLayoutSubviews */
    override func viewDidLayoutSubviews() {
        
        // set the layout for the collection view
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        
        let width = floor(self.collectionView!.frame.size.width/3.5)
        layout.itemSize = CGSize(width: width, height: width)
        collectionView!.collectionViewLayout = layout
    }
    
    // MARK: mapView Delegate Functions
    /*
     * mapView delegate function for the view for the annotation
    */
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        // return a normal pin annotation view set with the image of the normal pin
        let pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "myPin")
        pinAnnotationView.canShowCallout = false
        pinAnnotationView.image = UIImage(named:"pin2")
        return pinAnnotationView
    }

    // MARK: UICollectionViewDataSource Functions
    
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
    
    // MARK: UICollectionViewDelegate Functions
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        // get the cell and the photo that were selected
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! CustomCollectionViewCell
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        // check if we are allowed to make selections
        if allowsSelection {
            
            // if so, append the index to the selected indexes array
            selectedIndexes.append(indexPath)
        
            // then reconfigure the cell
            configureCell(cell, atIndexPath: indexPath)
        
            // update the bottom button
            updateBottomButton()
        }
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        
        // get the cell and photo
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! CustomCollectionViewCell
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        // check if selections allowed
        if allowsSelection {
            
            // find if the index is in selected indexes array
            if let index = find(selectedIndexes, indexPath) {
                // remove it from the array
                selectedIndexes.removeAtIndex(index)
            }
        
            // reconfigure the cell
            configureCell(cell, atIndexPath: indexPath)
        
            // update bottom button
            updateBottomButton()
        }
    }
    
    // MARK: - Fetched Results Controller
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
    
    // MARK: Fetched Results Delegate Functions
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()

    }
    
    // This method is called multiple times, once for each Photo object that is added, deleted, or changed.
    // We store the index paths of the changes into the three arrays.
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type{
            
        case .Insert:
            // inserting a photo
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            // deleting a photo
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            // updating a photo
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
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        // perform the batch updates
        dispatch_async(dispatch_get_main_queue()){
            self.collectionView!.performBatchUpdates({() -> Void in
                
                // insert photos
                for indexPath in self.insertedIndexPaths {
                    self.collectionView!.insertItemsAtIndexPaths([indexPath])
                }
                // delete photos
                for indexPath in self.deletedIndexPaths {
                    self.collectionView!.deleteItemsAtIndexPaths([indexPath])
                }
                // update photos
                for indexPath in self.updatedIndexPaths {
                    self.collectionView!.reloadItemsAtIndexPaths([indexPath])
                }
                
                // if there are no photos and the new collection button was pressed
                if self.pin.photos.count == 0 && self.deleteAllPressed {
                    // then fetch a new collection
                    self.fetchCollection()
                    
                    // reset the flag
                    self.deleteAllPressed = false
                }
                
                // update the bottom button
                self.updateBottomButton()
                
            }, completion: nil)
        }
    }
    
    // MARK: Other Functions
    
    /*
    * Fetches a new collection of images
    */
    func fetchCollection(){
        
        // set the flag
        downloadTaskInProgress = true
        
        // download the image paths
        Flickr.sharedInstance().downloadImagePathsForPin(pin, completionHandler: { (hasNoImages) -> Void in
            
            // check if the pin has images
            if hasNoImages {
                // if not, display the no images label
                dispatch_async(dispatch_get_main_queue()){
                    self.noPhotosLabel.hidden = false
                    self.updateBottomButton()
                }
            } else {
                // if it does have images, then fetch them
                Flickr.sharedInstance().fetchImagesForPin(self.pin, completionHandler: { (success) -> Void in
                    
                })
            }
            
            // once done, reset the flag
            self.downloadTaskInProgress = false
        })
    }
    
    /*
     * Function to save the context
    */
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    /*
    * Function to configure a cell
    */
    func configureCell(cell: CustomCollectionViewCell, atIndexPath indexPath: NSIndexPath){
        
        // get the photo
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        // set the cell's image to nil
        cell.image!.image = nil
        
        // change the alpha property if the cell has been selected
        if let index = find(selectedIndexes, indexPath) {
            cell.image!.alpha = 0.35
        } else {
            cell.image!.alpha = 1.0
        }
        
        // initialize an image with the default image placeholder
        var image = UIImage(named: "imgPlaceholder")
        
        // check if the photo's image exists
        if photo.image != nil {
            // if it does, set image to the photo's image
            image = photo.image
            
            // and hide the activity indicator
            cell.activityIndicator.hidden = true
        }
        // else, the photo's image does not exist
        else {
            // start animating the activity indicator and show it
            cell.activityIndicator.startAnimating()
            cell.activityIndicator.hidden = false
        }
        
        // set the cell's imageView image
        cell.image!.image = image
    }
    
    /*
    * Function to delete all the photos in a collection (when "New Collection is pressed)"
    */
    func deleteAllPhotos() {
        
        // we iterate over all photos in the fetched results controller
        for photo in fetchedResultsController.fetchedObjects as! [Photo] {
            
            // set the photo's image to nil (deletion happens in the Photo class)
            photo.image = nil
            
            // delete the object from the context
            sharedContext.deleteObject(photo)
        }
        
        // set the flag
        deleteAllPressed = true
        
        // save the context
        saveContext()
    }
    
    /*
    * Function to delete the user's selected photos
    */
    func deleteSelectedPhotos() {
        
        // array to store the photos we will delete
        var photosToDelete = [Photo]()
        
        // iterate over each index in the selected indexes in the array
        for indexPath in selectedIndexes {
            
            // append the photo at that index in the fetched results controller
            photosToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
        }
        
        // then iterate over each photo in the photosToDelete array
        for photo in photosToDelete {
            // set the image to nil (to delete it)
            photo.image = nil
            
            // delete the image from the context
            sharedContext.deleteObject(photo)
        }
        
        // reset the selected indexes array
        selectedIndexes = [NSIndexPath]()
        
        // save the context
        saveContext()
    }
    
    /*
    * Function that updates the bottom button based on the user's and app's actions
    */
    func updateBottomButton() {
        
        // scenario 1: there are no photos and no download in progress
        if pin.photos.count == 0 && !downloadTaskInProgress {
        
            // enable the button (it will show new collection)
            self.bottomButton.enabled = true
            
        } else if downloadTaskInProgress {
            
            // scenario 2: download in progress, disable
            self.bottomButton.enabled = false
            
        } else {
            
            // scenario 3: have all images been downloaded?
            if pin.allPhotosDownloaded() {
                self.bottomButton.enabled = true
                
                // enable selection of cells
                allowsSelection = true
            } else {
                self.bottomButton.enabled = pin.allPhotosDownloaded()
                
                // disable selections
                allowsSelection = false
            }
        }
        
        // if any image is selected then...
        if selectedIndexes.count > 0 {
            // set the button to show option to delete
            bottomButton.setTitle("Delete Selected", forState: UIControlState.Normal)
        } else {
            // else set the button to show option to fetch new collection
            bottomButton.setTitle("New Collection", forState: UIControlState.Normal)
        }
    }
    
    // MARK: IBAction Functions
    
    /*
    * Handle the bottom button being pressed
    */
    @IBAction func buttonButtonClicked() {
        
        // first check if we made any selections
        if selectedIndexes.isEmpty {
            
            // if we didn't make any selections, we pressed New Collection
            
            // we disable the button
            bottomButton.enabled = false
            
            // if there are no photos already, we fetch a new collection
            if pin.photos.count == 0 {
                fetchCollection()
            } else {
                // if there are photos present, we delete them all
                deleteAllPhotos()
            }
        } else {
            // else, we have made selections, so we only delete the selected photos
            deleteSelectedPhotos()
        }
    }
}