//
//  ATAnnotation.swift
//  Virtual Tourist
//
//  Created by Kinan Turjman on 7/30/15.
//  Copyright (c) 2015 Kinan Turman. All rights reserved.
//

import UIKit
import MapKit

func ==(lhs: ATAnnotation, rhs: ATAnnotation) -> Bool {
    println(lhs.coordinate.latitude == rhs.coordinate.latitude
        && lhs.coordinate.longitude == rhs.coordinate.longitude)
    
    return (lhs.coordinate.latitude == rhs.coordinate.latitude
        && lhs.coordinate.longitude == rhs.coordinate.longitude)
}

class ATAnnotation: NSObject, MKAnnotation, Equatable {
    
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0, 0)
    // var title: String = ""
    // var subtitle: String = ""
    var title: String
    
    init(coordinate: CLLocationCoordinate2D, title: String){
        self.coordinate = coordinate
        self.title = title
    }
}