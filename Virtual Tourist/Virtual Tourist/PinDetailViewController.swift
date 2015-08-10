//
//  PinDetailViewController.swift
//  Virtual Turist
//
//  Created by Kinan Turjman on 7/22/15.
//  Copyright (c) 2015 Kinan Turman. All rights reserved.
//

import UIKit
import CoreData

class PinDetailViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var selectedIndexes = [NSIndexPath]()
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    @IBOutlet weak var collectionView: UICollectionView?
    @IBOutlet weak var bottomButton: UIButton!
    
    var pin: Pin!
    
    var deleteAllPressed = false
    
    lazy var sharedContext = {
        CoreDataStackManager.sharedInstance().managedObjectContext!
        }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        // layout.sectionInset = UIEdgeInsets(top: 20, left: 10, bottom: 10, right: 10)
        // layout.itemSize = CGSize(width: 90, height: 90)
        
        collectionView!.backgroundColor = UIColor.whiteColor()
        collectionView!.allowsMultipleSelection = true
        
        self.view.addSubview(collectionView!)
        
        if pin.photos.count == 0 {
            showNoPhotoLabel()
        }
        
         updateBottomButton()
        // Step 2: Perform the fetch
        fetchedResultsController.performFetch(nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // printAllPinPhotos()
        
        Flickr.sharedInstance().fetchImagesForPin(pin)
        
        if pin.photos.count == 0 {
            fetchCollection()
        }
        
        bottomButton.enabled = false
    }
    
    override func viewDidLayoutSubviews() {
        // Lay out the collection view so that cells take up 1/3 of the width,
        // with no space in between.
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        
        let width = floor(self.collectionView!.frame.size.width/3.5)
        layout.itemSize = CGSize(width: width, height: width)
        collectionView!.collectionViewLayout = layout
    }
    
    func showNoPhotoLabel(){
        var label = UILabel(frame: CGRectMake(0, 0, 200, 21))
        label.center = CGPointMake(160, 284)
        label.textAlignment = NSTextAlignment.Center
        label.text = "This pin has no images."
        self.collectionView?.addSubview(label)
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
        println("fetching new collection...")
        Flickr.sharedInstance().downloadImagePathsForPin(pin)
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
        
        let CellIdentifier = "CollectionViewCell"
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CellIdentifier, forIndexPath: indexPath) as! CustomCollectionViewCell
        
        configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! CustomCollectionViewCell
        
        // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
        if let index = find(selectedIndexes, indexPath) {
            selectedIndexes.removeAtIndex(index)
        } else {
            selectedIndexes.append(indexPath)
        }
        
        // Then reconfigure the cell
         configureCell(cell, atIndexPath: indexPath)
         updateBottomButton()
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        
        println("in controllerWillChangeContent")
    }
    
    // The second method may be called multiple times, once for each Color object that is added, deleted, or changed.
    // We store the incex paths into the three arrays.
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type{
            
        case .Insert:
            println("Insert an item")
            // Here we are noting that a new Color instance has been added to Core Data. We remember its index path
            // so that we can add a cell in "controllerDidChangeContent". Note that the "newIndexPath" parameter has
            // the index path that we want in this case
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            println("Delete an item")
            // Here we are noting that a Color instance has been deleted from Core Data. We keep remember its index path
            // so that we can remove the corresponding cell in "controllerDidChangeContent". The "indexPath" parameter has
            // value that we want in this case.
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            println("Update an item.")
            // We don't expect Color instances to change after they are created. But Core Data would
            // notify us of changes if any occured. This can be useful if you want to respond to changes
            // that come about after data is downloaded. For example, when an images is downloaded from
            // Flickr in the Virtual Tourist app
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
        
        println("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        
        dispatch_async(dispatch_get_main_queue()){
            self.collectionView!.performBatchUpdates({() -> Void in
            
                for indexPath in self.insertedIndexPaths {
                    self.collectionView!.insertItemsAtIndexPaths([indexPath])
                }
            
                for indexPath in self.deletedIndexPaths {
                    println("deleted")
                    println("count: \(self.pin.photos.count)")
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
                self.bottomButton.enabled = self.allImagesLoaded()
                
            }, completion: nil)
        }
    }
    
    func configureCell(cell: CustomCollectionViewCell, atIndexPath indexPath: NSIndexPath){
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        cell.title?.text = " "
        cell.image!.image = nil
        
        if let index = find(selectedIndexes, indexPath) {
            cell.image!.alpha = 0.05
        } else {
            cell.image!.alpha = 1.0
        }
        
        var posterImage = UIImage(named: "posterPlaceHoldr")
        
        if photo.posterImage != nil {
            println("photo has image!")
            posterImage = photo.posterImage
        }
        else {
            println("image not available yet!")
        }
        
        cell.image!.image = posterImage
    }
    
    @IBAction func buttonButtonClicked() {
        
        //println("selected indexes: \(selectedIndexes.isEmpty)")
        
        if selectedIndexes.isEmpty {
            //println("deleting some...")
            if pin.photos.count == 0 {
                fetchCollection()
            } else {
                deleteAllColors()
            }
        } else {
            //println("deleting selected...")
            deleteSelectedColors()
        }
        
        saveContext()
    }
    
    func deleteAllColors() {
        
        for photo in fetchedResultsController.fetchedObjects as! [Photo] {
            photo.posterImage = nil
            sharedContext.deleteObject(photo)
        }
        
        deleteAllPressed = true
    }
    
    func deleteSelectedColors() {
        var colorsToDelete = [Photo]()
        
        for indexPath in selectedIndexes {
            colorsToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
        }
        
        for photo in colorsToDelete {
            photo.posterImage = nil
            sharedContext.deleteObject(photo)
        }
        
        selectedIndexes = [NSIndexPath]()
    }
    
    func updateBottomButton() {
        if selectedIndexes.count > 0 {
            bottomButton.setTitle("Delete Selected", forState: UIControlState.Normal)
        } else {
            bottomButton.setTitle("New Collection", forState: UIControlState.Normal)
        }
    }
    
    func allImagesLoaded() -> Bool {
        for photo in pin.photos {
            
            if photo.isDownloaded == false {
                return false
            }
        }
        return true
    }
    
    /*
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let photo = pin.photos[indexPath.row]
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionViewCell", forIndexPath: indexPath) as! CustomCollectionViewCell
        cell.backgroundColor = UIColor.blueColor()
        // cell.textLabel?.text = "\(indexPath.section):\(indexPath.row)"
        cell.title?.text = "\(indexPath.section):\(indexPath.row)"
        cell.image!.image = nil
        
        var posterImage = UIImage(named: "posterPlaceHoldr")
        
        if photo.posterImage != nil {
            println("photo has image!")
            posterImage = photo.posterImage
        }
        else {
            println("image not available yet!")
        }
        
        cell.image!.image = posterImage
        
        return cell
    }
*/
}