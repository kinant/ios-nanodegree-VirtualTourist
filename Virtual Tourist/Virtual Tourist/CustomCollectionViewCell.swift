//
//  CustomCollectionViewCell.swift
//  Virtual Turist
//
//  Created by Kinan Turjman on 7/22/15.
//  Copyright (c) 2015 Kinan Turman. All rights reserved.
//

import UIKit

/* Custom Collection View Cell */

class CustomCollectionViewCell: UICollectionViewCell {
    
    // the cell's properties
    // the cell's image
    @IBOutlet weak var image: UIImageView!
    
    // the cell's activity indicator that shows while downloading
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
}
