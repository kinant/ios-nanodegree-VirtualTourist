//
//  Pin.swift
//  Virtual Tourist
//
//  Created by KT on 7/22/15.
//  Copyright (c) 2015 Kinan Turman. All rights reserved.
//

import MapKit

class Pin {
    
    struct Keys {
        static let Coordinate = "coordinate"
        static let Photos = "photos"
    }
    
    var annotation: VTAnnotation!
    var photos: [Photo] = [Photo]()
    
    init(annotation: VTAnnotation){
        self.annotation = annotation
    }
}
