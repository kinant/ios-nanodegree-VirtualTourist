//
//  Photo.swift
//  Virtual Tourist
//
//  Created by KT on 7/22/15.
//  Copyright (c) 2015 Kinan Turman. All rights reserved.
//

import UIKit
import CoreData

@objc(Photo)

class Photo: NSManagedObject {
    
    struct Keys {
        static let ImagePath = "image_path"
    }
    
    @NSManaged var imagePath: String?
    @NSManaged var pin: Pin?
    @NSManaged var id: String?
    @NSManaged var isDownloaded: NSNumber?
    
    // this variable is used as a flag to mark if the photo is in the process of being deleted
    // that way, we do not try to use it (used in async photo data download)
    var isPreparingToDelete = false
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(imagePath: String, id: String, context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.imagePath = imagePath
        self.id = id
        
        self.isDownloaded = NSNumber(bool: false)
    }
    
    var posterImage: UIImage? {
        get {
            return Flickr.Caches.imageCache.imageWithIdentifier(id! + ".jpg")
        }
        set {
            // println("before: \(self.id)")
            // println("newvalue: \(newValue)")
            Flickr.Caches.imageCache.storeImage(newValue, withIdentifier: id! + ".jpg")
        }
    }
    
    override func prepareForDeletion() {
        println("photo will prepare to delete!!")
        println("id: \(self.id)")
        
        // set the flag
        self.isPreparingToDelete = true
        
        // check that the image has been downloaded
        // if self.isDownloaded == true {
            // set the image data to nil (this deletes it)
            posterImage = nil
        //}
    }
}