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
            "bbox": createBoundingBoxString(CLLocationCoordinate2DMake(pin.latitude, pin.longitude)),
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
    
    func downloadRandomImageForPin(imageUrl: String, completionHandler: (imageData: NSData?) -> Void) {
        println("downloading image at: \(imageUrl)")
        
        taskForImageWithSize(imageUrl, completionHandler: { (imageData, error) -> Void in
            
            completionHandler(imageData: imageData!)
            
        })
    }
    
    func getTopController() -> UIViewController?
    {
        if var topController = UIApplication.sharedApplication().keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            
            // topController should now be your topmost view controller
            return topController
        }
        
        return nil
    }
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    func downloadImagePathsForPin(pin: Pin){
        if pin.photos.isEmpty {
            Flickr.sharedInstance().searchPhotosByLatLon(pin, completionHandler: { (result, error) -> Void in
                if let photos = result {
                    for photo in photos {
                        if let imageURL = photo["url_m"] as? String {
                            let newPhoto = Photo(imagePath: imageURL, context: self.sharedContext)
                            newPhoto.pin = pin
                        }
                    }
                    self.fetchImagesForPin(pin)
                }
                self.saveContext()
            })
        }
    }
    
    func fetchImagesForPin(pin:Pin){
        
        println("attempting to download \(pin.photos.count) images!")
        
        for photo in pin.photos {
            let imageUrl = photo.imagePath!
            let url = NSURL(string: imageUrl)!
            let request = NSURLRequest(URL: url)
        
            println("downloading image at: \(imageUrl)")
            // let request = NSUrL
            let mainQueue = NSOperationQueue.mainQueue()
            
            NSURLConnection.sendAsynchronousRequest(request, queue: mainQueue, completionHandler: { (response, data, error) -> Void in
                if error == nil {
                    // Convert the downloaded data in to a UIImage object
                    let image = UIImage(data: data)
                
                    photo.posterImage = image
                    // self.saveContext()
                    println("image downloaded!!!")
                    println("current view controller: \(self.getTopController())")
                    let topController = self.getTopController()
                    
                    if let topNavController = topController as? UINavigationController {
                        println(topNavController.visibleViewController)
                        
                        if topNavController.visibleViewController is PinDetailViewController {
                            
                            let currentVisiblePin = (topNavController.visibleViewController as! PinDetailViewController).pin
                            
                            if currentVisiblePin == pin {
                                println("PINS MATCH!!")
                                (topNavController.visibleViewController as! PinDetailViewController).collectionView?.reloadData()
                            }
                        }
                        // return UIWindow.getVisibleViewControllerFrom(topController)
                    }
                }
                else {
                    println("Error: \(error.localizedDescription)")
                }
            })
        }
    }
}