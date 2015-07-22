//
//  Photo.swift
//  Virtual Tourist
//
//  Created by KT on 7/22/15.
//  Copyright (c) 2015 Kinan Turman. All rights reserved.
//

import UIKit

class Photo {
    
    struct Keys {
        static let ImagePath = "image_path"
    }
    
    var imagePath: String?
    
    init(imagePath: String) {
        self.imagePath = imagePath
    }
    
    var imagePhoto: UIImage? {
        get { return UIImage(named: "") }
        set { newValue }
    }
}
