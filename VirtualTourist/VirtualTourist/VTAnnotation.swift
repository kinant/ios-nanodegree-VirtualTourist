//
//  VTAnnotation.swift
//  Virtual Turist
//
//  Created by Kinan Turjman on 7/22/15.
//  Copyright (c) 2015 Kinan Turman. All rights reserved.
//

import UIKit
import MapKit

class VTAnnotation: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0, 0)
    // var title: String = ""
    // var subtitle: String = ""
    var index: Int
    
    init(coordinate: CLLocationCoordinate2D, index: Int){
        self.coordinate = coordinate
        self.index = index
    }
}
