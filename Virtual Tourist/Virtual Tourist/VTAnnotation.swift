//
//  VTAnnotation.swift
//  Virtual Turist
//
//  Created by Kinan Turjman on 7/22/15.
//  Copyright (c) 2015 Kinan Turman. All rights reserved.
//

import UIKit
import MapKit

func ==(lhs: VTAnnotation, rhs: VTAnnotation) -> Bool {
    return (lhs.coordinate.latitude == rhs.coordinate.latitude
        && lhs.coordinate.longitude == rhs.coordinate.longitude)
}

class VTAnnotation: NSObject, MKAnnotation, Equatable {
    
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0, 0)
    var index: Int!
    
    init(coordinate: CLLocationCoordinate2D, index: Int) {
        self.coordinate = coordinate
        self.index = index
    }
    
    func setNewCoordinate(newCoordinate: CLLocationCoordinate2D) {
        println("setting new coordinate!")
        willChangeValueForKey("coordinate")
        self.coordinate = newCoordinate
        didChangeValueForKey("coordinate")
    }
}
