//
//  Tixik.swift
//  Virtual Tourist
//
//  Created by Kinan Turjman on 7/29/15.
//  Copyright (c) 2015 Kinan Turman. All rights reserved.
//
/*
import Foundation
import MapKit

class Tixik: NSObject {
    
    var session: NSURLSession
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }

    func taskForData(coordinate: CLLocationCoordinate2D) -> NSURLSessionDataTask
    {
        let urlString = "http://www.tixik.com/api/nearby?lat=\(coordinate.latitude)&lng=\(coordinate.longitude)&limit=10&key=demo"
        
        println(urlString)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            var result = NSString(data: data, encoding:
                NSASCIIStringEncoding)!
            
            println(result)
            // let parsedResult = NSXMLParser.
            
        }
        
        task.resume()
        
        return task
    }
    
    // MARK: - Shared Instance
    class func sharedInstance() -> Tixik {
        struct Singleton {
            static var sharedInstance = Tixik()
        }
        return Singleton.sharedInstance
    }
    
}
*/

import Foundation
import MapKit

struct TouristAttraction
{
    let name: String
    let coordinate: CLLocationCoordinate2D
}

class Tixik: NSObject, NSXMLParserDelegate {
    
    var strXMLData:String = ""
    var currentElement:String = ""
    var passX:Bool=false
    var passY:Bool=false
    var passName:Bool=false
    var parser = NSXMLParser()
    
    var names = [String]()
    var gps_x = [Double]()
    var gps_y = [Double]()
    
    let attractions = [
        TouristAttraction(name: "test1", coordinate: CLLocationCoordinate2DMake(3, 1)),
        TouristAttraction(name: "test2", coordinate: CLLocationCoordinate2DMake(2, 2)),
        TouristAttraction(name: "test3", coordinate: CLLocationCoordinate2DMake(1, 3))
    ]
    
    func taskForData(coordinate: CLLocationCoordinate2D) -> [[String: AnyObject]] {
        let url = "http://www.tixik.com/api/nearby?lat=\(coordinate.latitude)&lng=\(coordinate.longitude)&limit=10&key=demo"
        var urlToSend: NSURL = NSURL(string: url)!
        // Parse the XML
        parser = NSXMLParser(contentsOfURL: urlToSend)!
        parser.delegate = self
        
        var success:Bool = parser.parse()
        
        var attractionDict = [[String : AnyObject]]()
        
        if success {
            println("parse success!")
            println(names)
            println(gps_x)
            println(gps_y)
            
            var newDictionary = [NSDictionary]()
            
            for var i = 0; i < names.count; i++ {
                var newEntry = ["name" : names[i], "x" : gps_x[i], "y" : gps_y[i]]
               attractionDict.append(newEntry as! [String : AnyObject])
            }
            
        } else {
            println("parse failure!")
        }
        
        println(attractionDict)
        
        return attractionDict
        
    }
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [NSObject : AnyObject]) {
        
        currentElement = elementName;
        
        if(elementName=="name" || elementName=="gps_x" || elementName=="gps_y")
        {
            if(elementName == "name"){
                passName = true;
            } else if elementName == "gps_x" {
                passX = true
            } else if elementName == "gps_y" {
                passY = true
            }
        }
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        currentElement = " ";
        
        if(elementName=="name" || elementName=="gps_x" || elementName=="gps_y")
        {
            if(elementName == "name"){
                passName = false;
            } else if elementName == "gps_x" {
                passX = false
            } else if elementName == "gps_y" {
                passY = false
            }
        }
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String?) {
        if passName {
            names.append(string!)
        }
        
        if passX {
            gps_x.append(string!.toDouble()!)
        }
        
        if passY {
            gps_y.append(string!.toDouble()!)
        }
    }
    
    func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) {
        NSLog("failure error: %@", parseError)
    }
    
    // MARK: - Shared Instance
    class func sharedInstance() -> Tixik {
        struct Singleton {
            static var sharedInstance = Tixik()
        }
        return Singleton.sharedInstance
    }
    
    /**
    Creates a dictionary with an optional
    entry for every element in an array.
    */
    func toDictionary<E, K, V>(
        array:       [E],
        transformer: (element: E) -> (key: K, value: V)?)
        -> Dictionary<K, V>
    {
        return array.reduce([:]) {
            (var dict, e) in
            if let (key, value) = transformer(element: e)
            {
                dict[key] = value
            }
            return dict
        }
    }
}
