//
//  Photo.swift
//  Virtual Tourist
//
//  Created by KT on 7/22/15.
//  Copyright (c) 2015 Kinan Turman. All rights reserved.
//

/* This file represents the data model for the Photo class */

import UIKit
import CoreData

@objc(Photo)

class Photo: NSManagedObject {
    
    struct Keys {
        static let ImagePath = "image_path"
    }
    
    // MARK: Core Data Managed Properties
    @NSManaged var imagePath: String? // the path for the image
    @NSManaged var pin: Pin? // the pin who "owns" this photo
    @NSManaged var id: String? // the photo id
    @NSManaged var isDownloaded: NSNumber? // flag to handle if this photo has had it's image data downloaded
    
    // MARK: Other Properties
    
    // this property is used as a flag to mark if the photo is in the process of being deleted.
    //That way, we do not try to use it (used in photo data download)
    var isPreparingToDelete = false
    
    // computed property for the photo's image
    var image: UIImage? {
        get {
            // get the image from the image cache
            return Flickr.Caches.imageCache.imageWithIdentifier(id! + ".jpg")
        }
        set {
            // set the image to the image cache
            Flickr.Caches.imageCache.storeImage(newValue, withIdentifier: id! + ".jpg")
        }
    }
    
    // MARK: Methods
    /*
    * Standard Core Data init method
    */
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    /**
    * Init Method
    *
    * The three argument Init method. The method has two goals:
    *  - insert the new Pin into a Core Data Managed Object Context
    *  - initialze the Photo's properties from an image path and id
    */
    init(imagePath: String, id: String, context: NSManagedObjectContext) {
        
        // get entity associated with the "Photo" type
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        
        // call init method inherited from MSManagedObject. ("Inserts" object into the context we pass as parameter)
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // set the properties
        self.imagePath = imagePath
        self.id = id
        
        // initialize the is downloaded flag to false
        self.isDownloaded = NSNumber(bool: false)
    }
    
    // MARK: Other Methods
    /*
    * Override the prepareForDeletion method. This method is called when the
    * object is in the process of getting deleted
    */
    override func prepareForDeletion() {
        // set the flag
        self.isPreparingToDelete = true
        
        // set the image to nil to delete it's data in memory cache and documents folder
        image = nil
    }
}