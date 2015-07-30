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
    
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var name: String
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(annotation: ATAnnotation, context: NSManagedObjectContext){
        
        let entity = NSEntityDescription.entityForName("Attraction", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.name = annotation.title
        self.latitude = annotation.coordinate.latitude
        self.longitude = annotation.coordinate.longitude
    }
    
    var annotation: ATAnnotation {
        get {
            return ATAnnotation(coordinate: CLLocationCoordinate2DMake(self.latitude, self.longitude), title: name)
        }
    }
}