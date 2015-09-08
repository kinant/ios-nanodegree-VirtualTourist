//
//  VTAnnotation.swift
//  Virtual Turist
//
//  Created by Kinan Turjman on 7/22/15.
//  Copyright (c) 2015 Kinan Turman. All rights reserved.
//

/* VTAnnotation class to represent a custom Annotation for Virtual Tourist Pins */

import UIKit
import MapKit

// In order to compare to pins, Pin conforms to the Equatable protocol
// https://developer.apple.com/library/ios//documentation/General/Reference/SwiftStandardLibraryReference/Equatable.html
// The == function must be implemented in the global scope
func ==(lhs: VTAnnotation, rhs: VTAnnotation) -> Bool {
    
    // two annotations are equal if their latitudes and logitudes are equal
    return (lhs.coordinate.latitude == rhs.coordinate.latitude
        && lhs.coordinate.longitude == rhs.coordinate.longitude)
}

class VTAnnotation: NSObject, MKAnnotation, Equatable {
    
    // property for the annotations coordinate
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0, 0)
    
    // init method
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
    
    /* 
     * This method sets the annotation's coordinate to a new coordinate. 
     * We use this method to update an annotation's coordinate in the map view without
     * having to remove and re-add it
     * http://stackoverflow.com/questions/2256177/how-to-move-a-mkannotation-without-adding-removing-it-from-the-map
    */
    func setNewCoordinate(newCoordinate: CLLocationCoordinate2D) {
        willChangeValueForKey("coordinate")
        self.coordinate = newCoordinate
        didChangeValueForKey("coordinate")
    }
}
