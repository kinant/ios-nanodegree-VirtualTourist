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
    
    /*
    * This method searches the Flickr API for photos based on latitude and longitude
    */
    func searchPhotosByLatLon(pin: Pin, completionHandler: (data: [[String: AnyObject]]?, error: NSError?) -> Void) {
        
        // set the method arguments
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
        
        // get the data from from Flickr
        Flickr.sharedInstance().getImagesFromFlickrBySearch(methodArguments as! [String : AnyObject], completionHandler: { (result, error) -> Void in
            
            // TODO: Check for errors
            completionHandler(data: result, error: error)
        })
    }
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    /*
    * This method is used to get the image paths (image url's) for a pin's photo collection
    * Only the URL data is downloaded. The image data itself is downloaded by another method.
    */
    func downloadImagePathsForPin(pin: Pin, completionHandler: (hasNoImages: Bool) -> Void){
        
        // first check that the photos array for a pin is empty
        if pin.photos.isEmpty {
            
            // if it is empty, then search flickr for the photos based on latitude and longitude
            Flickr.sharedInstance().searchPhotosByLatLon(pin, completionHandler: { (result, error) -> Void in
                
                // obtain the photos dicitonary array from the results
                if let photos = result {
                    
                    // for each photo dictionary
                    for photo in photos {
                        
                        // get the image url
                        if let imageURL = photo["url_m"] as? String {
                            
                            // get the image id
                            if let imageID = photo["id"] as? String {
                                
                                // create the new photo
                                let newPhoto = Photo(imagePath: imageURL, id: imageID, context: self.sharedContext)
                                
                                // set the photo's pin
                                newPhoto.pin = pin
                            }
                        }
                    }
                    // call the completion handler with false, since the pin does have images
                    completionHandler(hasNoImages: false)
                } else if error == nil {
                    // the pin does not have images, so call completion handler with true
                    completionHandler(hasNoImages: true)
                }
            })
        }
    }
    
    /*
    * This method is used to download the images for a pin's photo collection
    */
    func fetchImagesForPin(pin:Pin, completionHandler: (success: Bool) -> Void){
        
        // for each photo in the pin's photo collection
        for photo in pin.photos {
            
            // if the photo's image is nil (it hasn't been downloaded and saved)
            if photo.image == nil {
            
                // get the image url
                let imageUrl = photo.imagePath!
                
                // perform the task to download the image data
                Flickr.sharedInstance().taskForImage(imageUrl, completionHandler: { (imageData, error) -> Void in
                    
                    // check for error
                    if error == nil {
                        
                        // Convert the downloaded data in to a UIImage object
                        let image = UIImage(data: imageData!)
                        
                        // make sure the user hasn't deleted the pin while the image was downloading
                        if !photo.isPreparingToDelete {
                            
                            // set the image
                            photo.image = image
                            
                            // set the isDownloaded flag
                            photo.isDownloaded = NSNumber(bool: true)
                            
                            // save the context
                            self.saveContext()
                            
                            // check that all images have been downloaded to call the completion handler
                            if pin.allPhotosDownloaded() {
                                completionHandler(success: true)
                            }
                        }
                    }
                    else {
                        println("Error: \(error!.localizedDescription)")
                    }
                })
            }
        }
    }
}