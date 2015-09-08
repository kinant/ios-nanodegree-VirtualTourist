//
//  VTAnnotationView.swift
//  Virtual Tourist
//
//  Created by Kinan Turjman on 9/8/15.
//  Copyright (c) 2015 Kinan Turman. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class VTAnnotationView: MKPinAnnotationView {

    var activityIndicator = UIActivityIndicatorView()
    
    func showActivityIndicator(){
        
        activityIndicator.frame = CGRectMake(2, -35, 30.0, 30.0);
        
        activityIndicator.backgroundColor = UIColor.whiteColor()
        activityIndicator.alpha = 0.75
        
        activityIndicator.hidden = false
        activityIndicator.activityIndicatorViewStyle =
            UIActivityIndicatorViewStyle.White
        
        activityIndicator.backgroundColor = UIColor(patternImage: UIImage(named: "tower_square")!)
        
        dispatch_async(dispatch_get_main_queue()){
            self.addSubview(self.activityIndicator)
            self.activityIndicator.startAnimating()
        }
    }
    
    func showPhotoInActivityIndicator(){
        dispatch_async(dispatch_get_main_queue()){
            self.activityIndicator.backgroundColor = UIColor(patternImage: UIImage(named: "photo_square")!)
        }
    }
    
    func hideActivityIndicator(){
        dispatch_async(dispatch_get_main_queue()){
            self.activityIndicator.removeFromSuperview()
        }
    }
}