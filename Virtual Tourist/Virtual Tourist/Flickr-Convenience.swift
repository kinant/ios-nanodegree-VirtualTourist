//
//  Flickr-Convenience.swift
//  Virtual Tourist
//
//  Created by KT on 7/23/15.
//  Copyright (c) 2015 Kinan Turman. All rights reserved.
//

import Foundation
import MapKit

extension Flickr {
    
    func searchPhotosByLatLon(pin: Pin, completionHandler: (data: [[String: AnyObject]]?, error: NSError?) -> Void) {
        let methodArguments = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "per_page": Flickr.Resources.PER_PAGE,
            "bbox": createBoundingBoxString(pin.annotation.coordinate),
            "safe_search": SAFE_SEARCH,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK
        ]
        
        // getImageFromFlickrBySearch(methodArguments)
        Flickr.sharedInstance().getImageFromFlickrBySearch(methodArguments, completionHandler: { (result, error) -> Void in
            
            completionHandler(data: result, error: error)
        
        })
    }
    
    func createBoundingBoxString(location: CLLocationCoordinate2D) -> String {
        
        let latitude = Double(location.latitude)
        let longitude = Double(location.longitude)
        
        /* Fix added to ensure box is bounded by minimum and maximums */
        let bottom_left_lon = max(longitude - BOUNDING_BOX_HALF_WIDTH, LON_MIN)
        let bottom_left_lat = max(latitude - BOUNDING_BOX_HALF_HEIGHT, LAT_MIN)
        let top_right_lon = min(longitude + BOUNDING_BOX_HALF_HEIGHT, LON_MAX)
        let top_right_lat = min(latitude + BOUNDING_BOX_HALF_HEIGHT, LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    
    func downloadRandomImageForPin(pin: Pin, completionHandler: (imageData: NSData?) -> Void) {
        let randomPhotoIndex = Int(arc4random_uniform(UInt32(pin.photos.count)))
        let imageUrl = pin.photos[randomPhotoIndex].imagePath!
        
        println("downloading image at: \(imageUrl)")
        
        taskForImageWithSize(imageUrl, completionHandler: { (imageData, error) -> Void in
            
            completionHandler(imageData: imageData!)
            
        })
    }
}