//
//  Attraction.swift
//  Virtual Tourist
//
//  Created by Kinan Turjman on 7/30/15.
//  Copyright (c) 2015 Kinan Turman. All rights reserved.
//

import MapKit
import CoreData

@objc(Attraction)

class Attraction: NSManagedObject {
    
    struct Keys {
        static let Latitude = "latitude"
        static let Longitude = "longitude"
        static let Name = "name"
    }
    
    // MARK: Core Data Managed Properties
    @NSManaged var latitude: Double // the attraction's latitude
    @NSManaged var longitude: Double // the attraction's longitude
    @NSManaged var name: String // the attraction's name
    @NSManaged var pin: Pin? // the attraction's associated Pin
    
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
    *  - insert the new Attraction into a Core Data Managed Object Context
    *  - initialze the Attracion's properties from an annotation
    */
    init(annotation: ATAnnotation, context: NSManagedObjectContext){
        
        // get entity associated with the "Attraction " type
        let entity = NSEntityDescription.entityForName("Attraction", inManagedObjectContext: context)!
        
        // call init method inherited from MSManagedObject. ("Inserts" object into the context we pass as parameter)
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // set the properties
        self.name = annotation.title
        self.latitude = annotation.coordinate.latitude
        self.longitude = annotation.coordinate.longitude
    }
    
    // computed property for an attraction's annotation
    var annotation: ATAnnotation {
        get {
            // create and return the annotation
            return ATAnnotation(coordinate: CLLocationCoordinate2DMake(self.latitude, self.longitude), title: name)
        }
    }
}