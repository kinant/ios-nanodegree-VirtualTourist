//
//  Pin.swift
//  Virtual Tourist
//
//  Created by KT on 7/22/15.
//  Copyright (c) 2015 Kinan Turman. All rights reserved.
//

import MapKit
import CoreData
import UIKit

func ==(lhs:Pin, rhs:Pin) -> Bool {
    return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
}

@objc(Pin)

class Pin: NSManagedObject, Equatable {
    
    struct Keys {
        static let Latitude = "latitude"
        static let Longitude = "longitude"
        static let Photos = "photos"
    }

    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var photos: [Photo]
    @NSManaged var attractions: [Attraction]
    
    var downloadTaskInProgress =  false
    var activityIndicator = UIActivityIndicatorView()
    var annotation: VTAnnotation!
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(annotation: VTAnnotation, context: NSManagedObjectContext){
        
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.latitude = annotation.coordinate.latitude
        self.longitude = annotation.coordinate.longitude
        
        self.annotation = annotation
    }
    /*
    var annotation: VTAnnotation {
        get {
            return VTAnnotation(coordinate: CLLocationCoordinate2DMake(self.latitude, self.longitude), index: 0)
        }
        set {
            newValue
        }
    }
    */
}