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

/* Custom MKPinAnnotationView for our app's mapView pins 
 * Our pins will show activity indicators above them when their
 * data is being downloaded. These activity indicators also have
 * a background image representing the data they are downloading
*/

class VTPinAnnotationView: MKPinAnnotationView {
    
    // property for the activity indicator
    var activityIndicator = UIActivityIndicatorView()
    
    /*
     * Shows the activity indicator
    */
    func showActivityIndicator(){
        
        // set the frame
        activityIndicator.frame = CGRectMake(2, -35, 30.0, 30.0);
        
        // set alpha, hidden and style
        activityIndicator.alpha = 0.75
        activityIndicator.hidden = false
        activityIndicator.activityIndicatorViewStyle =
            UIActivityIndicatorViewStyle.White
        
        // set the backround to show the image of the tower
        activityIndicator.backgroundColor = UIColor(patternImage: UIImage(named: "tower_square")!)
        
        // add the indicator to the pin annotation view
        dispatch_async(dispatch_get_main_queue()){
            self.addSubview(self.activityIndicator)
            
            // animate the pin
            self.activityIndicator.startAnimating()
        }
    }
    
    /*
    * Changes the activity indicator so that it displays the photo icon as background
    */
    func showPhotoInActivityIndicator(){
        dispatch_async(dispatch_get_main_queue()){
            
            // change style
            self.activityIndicator.activityIndicatorViewStyle =
                UIActivityIndicatorViewStyle.Gray
            
            // change the background
            self.activityIndicator.backgroundColor = UIColor(patternImage: UIImage(named: "photo_square")!)
        }
    }
    
    /*
    * Removes the activity indicator
    */
    func hideActivityIndicator(){
        dispatch_async(dispatch_get_main_queue()){
            self.activityIndicator.removeFromSuperview()
        }
    }
}