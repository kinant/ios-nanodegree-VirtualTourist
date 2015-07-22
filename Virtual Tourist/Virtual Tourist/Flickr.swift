//
//  Flickr.swift
//  Virtual Tourist
//
//  Created by KT on 7/22/15.
//  Copyright (c) 2015 Kinan Turman. All rights reserved.
//

import Foundation

class Flickr: NSObject {
    
    typealias CompletionHander = (result: AnyObject!, error: NSError?) -> Void
    
    var session: NSURLSession
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    // MARK: - All purpose task method for data
    //func getImageFromFlickrBySearch(methodArguments: [String : AnyObject]) {
    func getImageFromFlickrBySearch(parameters: [String : AnyObject], completionHandler: CompletionHander) -> NSURLSessionDataTask {
        let urlString = BASE_URL + Flickr.escapedParameters(parameters)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                println("Could not complete the request \(error)")
            } else {
                
                var parsingError: NSError? = nil
                let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
                
                if let photosDictionary = parsedResult.valueForKey("photos") as? [String:AnyObject] {
                    
                    if let totalPages = photosDictionary["pages"] as? Int {
                        
                        /* Flickr API - will only return up the 4000 images (100 per page * 40 page max) */
                        let pageLimit = min(totalPages, 40)
                        let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                        self.getImageFromFlickrBySearchWithPage(parameters, pageNumber: randomPage, completionHandler: completionHandler)
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
    
    func getImageFromFlickrBySearchWithPage(methodArguments: [String : AnyObject], pageNumber: Int, completionHandler: CompletionHander) -> NSURLSessionDataTask {
        
        /* Add the page to the method's arguments */
        var withPageDictionary = methodArguments
        withPageDictionary["page"] = pageNumber
        
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + Flickr.escapedParameters(withPageDictionary)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                println("Could not complete the request \(error)")
            } else {
                var parsingError: NSError? = nil
                let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
                
                println(parsedResult)
                
                if let photosDictionary = parsedResult.valueForKey("photos") as? [String:AnyObject] {
                    
                    var totalPhotosVal = 0
                    if let totalPhotos = photosDictionary["total"] as? String {
                        totalPhotosVal = (totalPhotos as NSString).integerValue
                    }
                    
                    if totalPhotosVal > 0 {
                        if let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] {
                            
                            dataPhotosArray = photosArray
                            
                        } else {
                            println("Cant find key 'photo' in \(photosDictionary)")
                        }
                    } else {
                        dispatch_async(dispatch_get_main_queue(), {
                            
                        })
                    }
                } else {
                    println("Cant find key 'photos' in \(parsedResult)")
                }
            }
        }
        
        task.resume()
    }
    
    // MARK: - All purpose task method for images
    
    func taskForImageWithSize(size: String, filePath: String, completionHandler: (imageData: NSData?, error: NSError?) ->  Void) -> NSURLSessionTask {
        let urlComponents = [size, filePath]
        let baseURL = NSURL(string: " ")!
        let url = baseURL.URLByAppendingPathComponent(size).URLByAppendingPathComponent(filePath)
        
        println(url)
        
        let request = NSURLRequest(URL: url)
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                let newError = Flickr.errorForData(data, response: response, error: downloadError)
                completionHandler(imageData: nil, error: newError)
            } else {
                completionHandler(imageData: data, error: nil)
            }
        }
        task.resume()
        return task
    }

    
    // MARK: - Helpers
    
    // Try to make a better error, based on the status_message from TheMovieDB. If we cant then return the previous error
    class func errorForData(data: NSData?, response: NSURLResponse?, error: NSError) -> NSError {
        if let parsedResult = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments, error: nil) as? [String : AnyObject] {
            //if let errorMessage = parsedResult[TheMovieDB.Keys.ErrorStatusMessage] as? String {
              //  let userInfo = [NSLocalizedDescriptionKey : errorMessage]
                //return NSError(domain: "TMDB Error", code: 1, userInfo: userInfo)
            //}
        }
        return error
    }
    
    // Parsing the JSON
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: CompletionHander) {
        var parsingError: NSError? = nil
        let parsedResult: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError)
        if let error = parsingError {
            completionHandler(result: nil, error: error)
        } else {
            println("Step 4 - parseJSONWithCompletionHandler is invoked.")
            completionHandler(result: parsedResult, error: nil)
        }
    }
    
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
    
    // MARK: - Shared Image Cache
    
    struct Caches {
        static let imageCache = ImageCache()
    }
}