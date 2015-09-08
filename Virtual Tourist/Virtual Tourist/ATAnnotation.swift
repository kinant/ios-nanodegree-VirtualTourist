//
//  ATAnnotation.swift
//  Virtual Tourist
//
//  Created by Kinan Turjman on 7/30/15.
//  Copyright (c) 2015 Kinan Turman. All rights reserved.
//

/* VTAnnotation class to represent a custom Annotation for Virtual Tourist Attractions */

import UIKit
import MapKit

// In order to compare to annotations, ATAnnotation conforms to the Equatable protocol
// https://developer.apple.com/library/ios//documentation/General/Reference/SwiftStandardLibraryReference/Equatable.html
// The == function must be implemented in the global scope
func ==(lhs: ATAnnotation, rhs: ATAnnotation) -> Bool {
    // two pins are equal if their latitudes and logitudes are equal
    return (lhs.coordinate.latitude == rhs.coordinate.latitude
        && lhs.coordinate.longitude == rhs.coordinate.longitude)
}

class ATAnnotation: NSObject, MKAnnotation, Equatable {
    
    // property for the annotations coordinate
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0, 0)
    
    // property for the annotation's title
    var title: String
    
    // init method
    init(coordinate: CLLocationCoordinate2D, title: String){
        self.coordinate = coordinate
        self.title = title
    }
}