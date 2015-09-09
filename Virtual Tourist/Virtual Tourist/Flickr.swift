//
//  Flickr.swift
//  Virtual Tourist
//
//  Created by KT on 7/22/15.
//  Copyright (c) 2015 Kinan Turman. All rights reserved.
//

import Foundation

class Flickr: NSObject {
    
    // properties
    var session: NSURLSession // the session
    
    // init method
    override init() {
        // initialize the session
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    // MARK: - All purpose task methods for data
    
    /*
     * This method is used to get the data on the images based on a search by Flickr.
    */
    func getImagesFromFlickrBySearch(parameters: [String : AnyObject], completionHandler: (result: [[String: AnyObject]]?, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        // build the url
        let urlString = Flickr.Constants.BASE_URL + Flickr.escapedParameters(parameters)
        let url = NSURL(string: urlString)!
        
        // create the request
        let request = NSURLRequest(URL: url)
        
        // run the task
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            // check for error
            if let error = downloadError {
                println("Could not complete the request \(error.localizedDescription)")
            } else {
                
                // parse JSON results
                var parsingError: NSError? = nil
                let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
                
                // obtain the dictionary of photos from the parsed results
                if let photosDictionary = parsedResult.valueForKey("photos") as? [String:AnyObject] {
                    
                    // get the total number of pages
                    if let totalPages = photosDictionary["pages"] as? Int {
                        
                        /* Flickr API - will only return up the 4000 images (100 per page * 40 page max) */
                        // determine total possible pages
                        let totalPossiblePages = Int(Flickr.Values.MAX_RESULTS/Flickr.Resources.PER_PAGE.toInt()!)
                        
                        // determine the page limit
                        let pageLimit = min(totalPages, totalPossiblePages)
                        
                        // obtain a random page
                        let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                        
                        // perform task to get the images from a page in flickr
                        self.getImagesFromFlickrBySearchWithPage(parameters, pageNumber: randomPage, completionHandler: completionHandler)
                    
                    } else {
                        println("Cant find key 'pages' in \(photosDictionary)")
                    }
                } else {
                    println("Cant find key 'photos' in \(parsedResult)")
                }
            }
        }
        
        task.resume()
        
        return task
    }
    
    /*
    * This method is used to get the data on the images in a specific page, based on a search by Flickr.
    */
    func getImagesFromFlickrBySearchWithPage(methodArguments: [String : AnyObject], pageNumber: Int, completionHandler: (result: [[String: AnyObject]]?, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        // add the page number to the method arguments
        var withPageDictionary = methodArguments
        withPageDictionary["page"] = pageNumber
        
        // build the url
        let urlString = Flickr.Constants.BASE_URL + Flickr.escapedParameters(withPageDictionary)
        let url = NSURL(string: urlString)!
        
        // initialize the requerst
        let request = NSURLRequest(URL: url)
        
        // run the task
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            // check for errors
            if let error = downloadError {
                println("Could not complete the request: \(error.localizedDescription)")
            } else {
                
                // parse JSON Data
                var parsingError: NSError? = nil
                let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
                
                // obtain the photos dictionary from the parsed results
                if let photosDictionary = parsedResult.valueForKey("photos") as? [String:AnyObject] {
                    
                    // variable to hold the total number of photos
                    var totalPhotosVal = 0
                    
                    // determine the total number of photos based on the "total" value in the dictionary
                    if let totalPhotos = photosDictionary["total"] as? String {
                        // set the total value
                        totalPhotosVal = (totalPhotos as NSString).integerValue
                    }
                    
                    // check that the total number of photos is greater than 0
                    if totalPhotosVal > 0 {
                        
                        // obtain the array of photos
                        if let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] {
                            // call completion handler with the photos array data
                            completionHandler(result: photosArray, error: nil)
                        } else {
                            println("Cant find key 'photo' in \(photosDictionary)")
                        }
                    } else {
                        // this pin has no images, call completion handler with nil for result
                        completionHandler(result: nil, error: nil)
                    }
                } else {
                    println("Cant find key 'photos' in \(parsedResult)")
                }
            }
        }
        
        task.resume()
        
        return task
    }
    
    /*
    * This method is used to download the data of an image
    */
    func taskForImage(imageUrl: String, completionHandler: (imageData: NSData?, error: NSError?) ->  Void) -> NSURLSessionTask {
        
        // build the url
        let url = NSURL(string: imageUrl)!
        
        // create the request
        let request = NSURLRequest(URL: url)
        
        // create the task
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            // check for error
            if let error = downloadError {
                println("Error: \(downloadError.localizedDescription)")
                completionHandler(imageData: nil, error: error)
            } else {
                // no error, call completion handler with the image data
                completionHandler(imageData: data, error: nil)
            }
        }
        
        task.resume()
        
        return task
    }

    // MARK: - Helpers
    
    // URL Encoding a dictionary into a parameter string
    class func escapedParameters(parameters: [String : AnyObject]) -> String {
        var urlVars = [String]()
        for (key, value) in parameters {
            // Make sure that it is a string value
            let stringValue = "\(value)"
            
            // Escape it
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            // Append it
            urlVars += [key + "=" + "\(escapedValue!)"]
        }
        return (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
    }
    
    // MARK: - Shared Instance
    class func sharedInstance() -> Flickr {
        struct Singleton {
            static var sharedInstance = Flickr()
        }
        return Singleton.sharedInstance
    }
    
    // MARK: - Shared Context
    var sharedContext = {
        CoreDataStackManager.sharedInstance().managedObjectContext!
    }()
    
    // MARK: - Shared Image Cache
    struct Caches {
        static let imageCache = ImageCache()
    }
}
