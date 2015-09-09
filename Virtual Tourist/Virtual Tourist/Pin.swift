//
//  Pin.swift
//  Virtual Tourist
//
//  Created by KT on 7/22/15.
//  Copyright (c) 2015 Kinan Turman. All rights reserved.
//

/* This file represents the data model for the Pin class */

import MapKit
import CoreData
import UIKit

// In order to compare to pins, Pin conforms to the Equatable protocol
// https://developer.apple.com/library/ios//documentation/General/Reference/SwiftStandardLibraryReference/Equatable.html
// The == function must be implemented in the global scope
func ==(lhs:Pin, rhs:Pin) -> Bool {
    
    // two pins are equal if their latitudes and logitudes are equal
    return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
}

@objc(Pin)

class Pin: NSManagedObject, Equatable {
    
    // MARK: Core Data Managed Properties
    @NSManaged var latitude: Double // the pin's latitude
    @NSManaged var longitude: Double // the pin's longitude
    @NSManaged var photos: [Photo] // the pin's photo collection
    @NSManaged var attractions: [Attraction] // the pin's attractions array
    
    // MARK: Other properties
    // These properties are not persisted
    var downloadTaskInProgress =  false // flag for when a pin has a download task in progress

    var annotation: VTAnnotation! // the annotation associated with the pin
    
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
    * The Two argument Init method. The method has two goals:
    *  - insert the new Pin into a Core Data Managed Object Context
    *  - initialze the Pin's properties from an annotation
    */

    init(annotation: VTAnnotation, context: NSManagedObjectContext){
        
        // get entity associated with the "Pin " type
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        
        // call init method inherited from MSManagedObject. ("Inserts" object into the context we pass as parameter)
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // set the properties
        self.latitude = annotation.coordinate.latitude
        self.longitude = annotation.coordinate.longitude
        self.annotation = annotation
    }
    
    /*
    * Method that checks whether a pin has had all the photos in it's collection dowloaded
    */
    func allPhotosDownloaded() -> Bool {
        
        // iterate over each photo
        for photo in self.photos {
            // if any photo is not dowloaded, return false
            if photo.isDownloaded == false {
                return false
            }
        }
        // all (possible) photos downloaded, return true
        return true
    }
}