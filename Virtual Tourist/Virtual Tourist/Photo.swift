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
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(imagePath: String, id: String, context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.imagePath = imagePath
        self.id = id
    }
    
    var posterImage: UIImage? {
        get {
            return Flickr.Caches.imageCache.imageWithIdentifier(id! + ".jpg")
        }
        set {
            Flickr.Caches.imageCache.storeImage(newValue, withIdentifier: id! + ".jpg")
        }
    }
}