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
            "lat": pin.latitude,
            "lon": pin.longitude,
            "safe_search": SAFE_SEARCH,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK
        ]
        
        Flickr.sharedInstance().getImagesFromFlickrBySearch(methodArguments as! [String : AnyObject], completionHandler: { (result, error) -> Void in
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
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    func downloadImagePathsForPin(pin: Pin, completionHandler: (hasNoImages: Bool) -> Void){
        
        println("attempting to download image paths for pin...")
        println("is empty? \(pin.photos.isEmpty)")
        
        if pin.photos.isEmpty {
            Flickr.sharedInstance().searchPhotosByLatLon(pin, completionHandler: { (result, error) -> Void in
                println("searching for photos...")
                // println("result: \(result)")
                // println("error \(error?.localizedDescription)")
                
                if let photos = result {
                    
                    if photos.count == 0 {
                        println("pin has no images!")
                    }
                    
                    for photo in photos {
                        if let imageURL = photo["url_m"] as? String {
                            
                            if let imageID = photo["id"] as? String {
                                let newPhoto = Photo(imagePath: imageURL, id: imageID, context: self.sharedContext)
                                println("created new photo with id \(imageID)")
                                newPhoto.pin = pin
                            }
                        }
                    }
                    
                    println("photo count: \(photos.count)")
                    completionHandler(hasNoImages: false)
                } else if error == nil {
                    completionHandler(hasNoImages: true)
                }
                self.saveContext()
                self.fetchImagesForPin(pin)
            })
        }
    }
    
    func fetchImagesForPin(pin:Pin){
        
        println("attempting to download \(pin.photos.count) photos!")
        
        for photo in pin.photos {
            
            if photo.posterImage == nil {
            
                let imageUrl = photo.imagePath!
                let url = NSURL(string: imageUrl)!
                let request = NSURLRequest(URL: url)
        
                let mainQueue = NSOperationQueue.mainQueue()
            
                NSURLConnection.sendAsynchronousRequest(request, queue: mainQueue, completionHandler: { (response, data, error) -> Void in
                    if error == nil {
                        // Convert the downloaded data in to a UIImage object
                        let image = UIImage(data: data)
                        
                        // make sure the user hasn't deleted the pin while the image was downloading
                        if !photo.isPreparingToDelete {
                            println("image downloaded!")
                            photo.posterImage = image
                            photo.isDownloaded = NSNumber(bool: true)
                        }
                        
                    }
                    else {
                        println("Error: \(error.localizedDescription)")
                    }
                })
            }
        }
    }
}