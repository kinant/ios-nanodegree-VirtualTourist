//
//  MapViewController.swift
//  Virtual Turist
//
//  Created by Kinan Turjman on 7/22/15.
//  Copyright (c) 2015 Kinan Turman. All rights reserved.
//
import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {

    var pins = [Pin]()
    var pinCount = 0
    var selectedPinIndex = 0
    
    var pinToBeAdded: Pin!
    
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var mapViewSuperView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var hideAttractionsButton: UIButton!
    
    var attractionsHidden = false
    var inDeleteMode = false
    // var pinDownloadTaskInProgress = false
    
    var annotationToAdd: VTAnnotation!
    
    lazy var sharedContext = {
        CoreDataStackManager.sharedInstance().managedObjectContext!
        }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        mapView.delegate = self
        mapView.mapType = .Standard
        mapView.userInteractionEnabled = true
        
        self.view.userInteractionEnabled = true
        
        // load region
        let defaults = NSUserDefaults.standardUserDefaults()
        let latitude = defaults.doubleForKey("latitude")
        let longitude = defaults.doubleForKey("longitude")
        let spanLatDelta = defaults.doubleForKey("spanLatDelta")
        let spanLongDelta = defaults.doubleForKey("spanLongDelta")
        
        let span = MKCoordinateSpan(latitudeDelta: spanLatDelta, longitudeDelta: spanLongDelta)
        let region = MKCoordinateRegion(center: CLLocationCoordinate2DMake(latitude, longitude), span: span)
        
        if latitude != 0.0 && longitude != 0.0 {
            mapView.setRegion(region, animated: false)
        }
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self , action: "handleLongPress:")
        longPressGestureRecognizer.minimumPressDuration = 1.0
        self.mapView.addGestureRecognizer(longPressGestureRecognizer)
        longPressGestureRecognizer.cancelsTouchesInView = false
        
        pins = fetchAllPins()
        
        pinCount = pins.count
        /*
        for pin in pins {
            println("\(pin.annotation.coordinate.latitude)")
            println("\(pin.annotation.coordinate.longitude)")
        }
        */
        addPins()
    }
    
    func handleLongPress(recognizer: UILongPressGestureRecognizer){
        // println("long press!")
        var point = recognizer.locationInView(self.mapView)
        var locationCoordinate = self.mapView.convertPoint(point, toCoordinateFromView: self.mapView)
        
        if !inDeleteMode {
            if(recognizer.state == UIGestureRecognizerState.Began){
                println("adding pin")
                addPin(locationCoordinate)
            } else if (recognizer.state == UIGestureRecognizerState.Changed){
                println("moving pin!")
                //dispatch_async(dispatch_get_main_queue()){
                    self.annotationToAdd.setNewCoordinate(locationCoordinate)
                    self.pins[pinCount].latitude = locationCoordinate.latitude
                    self.pins[pinCount].longitude = locationCoordinate.longitude
                    println("index: \(self.annotationToAdd.index)")
            //}
            // mapView.viewForAnnotation(annotationToAdd)
            } else if recognizer.state == .Ended {
                if annotationToAdd != nil {
                    var test = mapView.viewForAnnotation(annotationToAdd)
                
                    dispatch_async(dispatch_get_main_queue()){
                    // test.setDragState(.Ending, animated: true)
                    // println(test.dragState.rawValue)
                        // self.addAttractionsForPin(self.pins[self.pinCount])
                        self.addPinComplete(self.pins[self.pinCount])
                        test.image = UIImage(named: "pin2")
                    }
                    annotationToAdd = nil
                }
            }
        }
    }
    /*
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        
        println("touches began!")
        
    }
    */
    /*
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        
        println("touches moved!")
        
        if annotationToAdd != nil {
            
            var test = mapView.viewForAnnotation(annotationToAdd)
            test.setDragState(.Dragging, animated: true)
            println(test.dragState.rawValue)
            
            let touch = touches.first as! UITouch
            let point = touch.locationInView(self.mapView)
            
            var locationCoordinate = self.mapView.convertPoint(point, toCoordinateFromView: self.mapView)
        
            println("new location lat/long: \(locationCoordinate.latitude), \(locationCoordinate.longitude)")
            dispatch_async(dispatch_get_main_queue()) {
                self.annotationToAdd.setNewCoordinate(locationCoordinate)
            }
        
            println("pin location lat/long: \(annotationToAdd.coordinate.latitude), \(annotationToAdd.coordinate.longitude)")
        }
    }
    */
    override func touchesCancelled(touches: Set<NSObject>!, withEvent event: UIEvent!) {
        println("touches cancelled")
    }
    /*
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        println("touches ended")
        
        if annotationToAdd != nil {
            var test = mapView.viewForAnnotation(annotationToAdd)
            
            dispatch_async(dispatch_get_main_queue()){
                test.setDragState(.Ending, animated: true)
                println(test.dragState.rawValue)
            }
            
            addAttractionsForPin(pinToBeAdded)
        
            annotationToAdd = nil
        }
    }
    */
    
    /*
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        
        println("did change drag state...")
        println(newState.rawValue)
        
        switch (newState) {
        case .Starting:
            view.dragState = .Dragging
        case .Ending, .Canceling:
            view.dragState = .None
        default: break
        }
    }
*/
    
    func addPins(){
        for pin in pins {
            mapView.addAnnotation(pin.annotation)
            // add attractions
            for attraction in pin.attractions {
                mapView.addAnnotation(attraction.annotation)
            }
        }
    }
    
    func addAttractionsForPin(pin: Pin){
        var location = pin.annotation.coordinate
        var attractions = Tixik.sharedInstance().taskForData(location)
        
        for attraction in attractions {
            
            let name = attraction["name"] as! String
            let x = attraction["x"] as! Double
            let y = attraction["y"] as! Double
            
            let newAnnot = ATAnnotation(coordinate: CLLocationCoordinate2DMake(x, y), title: name)
            let newAttraction = Attraction(annotation: newAnnot, context: sharedContext)
            newAttraction.pin = pin
            
            if !attractionsHidden {
                dispatch_async(dispatch_get_main_queue()){
                    self.mapView.addAnnotation(newAnnot)
                }
            }
        }
    }
    
    func addPin(location: CLLocationCoordinate2D){
        let annotation = VTAnnotation(coordinate: location, index: pinCount)
        mapView.addAnnotation(annotation)
        // setCenterOfMapToLocation(location)
        
        let newPin = Pin(annotation: annotation, context: sharedContext)
        
        pins.append(newPin)
        
        self.annotationToAdd = annotation
        
        
        // addAttractionsForPin(newPin)
    }
    
    func addPinComplete(newPin: Pin){
        CoreDataStackManager.sharedInstance().saveContext()
        
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        
        newPin.downloadTaskInProgress = true
        
        Flickr.sharedInstance().downloadImagePathsForPin(newPin, completionHandler: { (hasNoImages) -> Void in
            newPin.downloadTaskInProgress = false
            self.addAttractionsForPin(newPin)
        })
        
        // pinToBeAdded = newPin
        pinCount++
    }
    
    func fetchAllPins() -> [Pin] {
        let error: NSErrorPointer = nil
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        let results = sharedContext.executeFetchRequest(fetchRequest, error: error)
        if error != nil {
            println("Error in fetchAllActors(): \(error)")
        }
        return results as! [Pin]
    }
    
    func setCenterOfMapToLocation(location: CLLocationCoordinate2D) {
        let span = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        println("region did change!")
        println("region: \(mapView.region)")
        println("span: \(mapView.region.span)")
        
        // var myRegion: AnyObject? = mapView.region as? AnyObject
        
        // var newObject = mapView.region as! AnyObject
        // NSKeyedArchiver.archiveRootObject(mapView.region, toFile: mapStateFilePath)
        // NSUserDefaults.standardUserDefaults().setObject(mapView.region, forKey: "myRegion")
        //NSUserDefaults.standardUserDefaults().setObject(myRegion, forKey: "myRegion")
        //NSUserDefaults.standardUserDefaults().setFloat(22.5, forKey: "test")
        
        let defaults = NSUserDefaults.standardUserDefaults()
        
        let latitude = mapView.region.center.latitude
        let longitude = mapView.region.center.longitude
        let spanLatDelta = mapView.region.span.latitudeDelta
        let spanLongDelta = mapView.region.span.longitudeDelta
        
        defaults.setDouble(latitude, forKey: "latitude")
        defaults.setDouble(longitude, forKey: "longitude")
        defaults.setDouble(spanLatDelta, forKey: "spanLatDelta")
        defaults.setDouble(spanLongDelta, forKey: "spanLongDelta")
        
    }
    
    func mapView(mapView: MKMapView!, didAddAnnotationViews views: [AnyObject]!) {
        
        for view in views {
            var annotationView = view as! MKAnnotationView
            var endFrame = annotationView.frame
            
            annotationView.frame = CGRectOffset(endFrame, 0, -500)
            
            UIView.animateWithDuration(0.5, animations: {
                annotationView.frame = endFrame
            })
        }
    }
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        if annotation is VTAnnotation {
            // println("is VT annotation")
            let pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "myPin")
            pinAnnotationView.draggable = true
            pinAnnotationView.canShowCallout = false
            // pinAnnotationView.animatesDrop = true
            pinAnnotationView.image = UIImage(named: "pin2")
            
            if annotationToAdd != nil {
                pinAnnotationView.image = UIImage(named:"floating_pin")
                //pinAnnotationView.setDragState(.Starting, animated: true)
                //println("initial drag state: \(pinAnnotationView.dragState.rawValue)")
            }
            
            return pinAnnotationView
        } else if annotation is ATAnnotation {
           // println("is AT annotation")
            let pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "atPin")

            pinAnnotationView.canShowCallout = true

            pinAnnotationView.image = UIImage(named:"pin")
            // pinAnnotationView.animatesDrop = true
            return pinAnnotationView
        }
        return nil
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        var pinDetailVC = (segue.destinationViewController as! PinDetailViewController)
        
        if selectedPinIndex >= 0  {
            let selectedPin = pins[selectedPinIndex]
            pinDetailVC.pin = selectedPin
            
            // println("count: \(selectedPin.photos.count)")
            // println("downloading: \(selectedPin.downloadTaskInProgress)")
            
            if selectedPin.photos.count == 0 && !selectedPin.downloadTaskInProgress {
                // println("empty and no download in progress...fetching new collection!")
                pinDetailVC.fetchCollection()
            }
        }
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        
        println("annotation view selected!")
        
        if let selectedAnnotation = mapView.selectedAnnotations[0] as? VTAnnotation {
            
            selectedPinIndex = returnSelectedPinIndex(selectedAnnotation)
            
            println("selected: \(selectedPinIndex)")
            
            if inDeleteMode {
                println("will attempt to delete pin!")
                deletePin(pins[selectedPinIndex])
            } else {
                performSegueWithIdentifier("showPinDetail", sender: self)
            }
            mapView.deselectAnnotation(selectedAnnotation , animated: true)
        }
    }
    
    func deletePin(pin: Pin) {
        mapView.removeAnnotation(mapView.selectedAnnotations[0] as? VTAnnotation)
        deleteAttractionsForPin(pin)
        sharedContext.deleteObject(pin)
        sharedContext.save(nil)
    }
    
    func deleteAttractionsForPin(pin: Pin){
        
        for var i = 0; i < pin.attractions.count; i++ {
            for var j = 0; j < mapView.annotations.count; j++ {

                if let attraction = mapView.annotations[j] as? ATAnnotation {
                    if pin.attractions[i].annotation == attraction {
                        mapView.removeAnnotation(attraction)
                    }
                }
            }
        }
    }
    
    func hideAttractions() {
        for pin in pins {
            deleteAttractionsForPin(pin)
        }
        attractionsHidden = true
    }
    
    func showAttractions() {
        for pin in pins {
            // add attractions
            for attraction in pin.attractions {
                mapView.addAnnotation(attraction.annotation)
            }
        }
        attractionsHidden = false
    }
    
    func returnSelectedPinIndex(annotation: VTAnnotation) -> Int {
        
        // println("pin count: \(pins.count)")
        for var i = 0; i < pins.count; i++ {
            // println("pin index: \(pin.index)")
            if pins[i].annotation == annotation {
                return i
            }
        }
        return -1
    }
    
    func mapView(mapView: MKMapView!, didDeselectAnnotationView view: MKAnnotationView!) {
        // println("deselect!")
    }
    
    @IBAction func editButtonPressed(sender: UIBarButtonItem) {
        if sender.title == "Edit" {
            inDeleteMode = true
            sender.title = "Cancel"
            bottomView.hidden = false
            // hideAttractionsButton.hidden = true
            // hideAttractionsButton.bounds.origin.y -= 60
            
            if !attractionsHidden {
                // hideAttractions()
            }
            // mapViewSuperView.frame.origin.y -= bottomView.frame.height
        } else {
            inDeleteMode = false
            sender.title = "Edit"
            bottomView.hidden = true
            // mapViewSuperView.frame.origin.y += bottomView.frame.height
            // hideAttractionsButton.hidden = false
            // hideAttractionsButton.bounds.origin.y += 60
            
            if attractionsHidden {
                // showAttractions()
            }
        }
    }
    
    @IBAction func hideAttractions(sender: UIButton) {
        if sender.titleLabel?.text == "HIDE ATTRACTIONS" {
            sender.setTitle("SHOW ATTRACTIONS", forState: .Normal)
            hideAttractions()
        } else {
            sender.setTitle("HIDE ATTRACTIONS", forState: .Normal)
            showAttractions()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var mapStateFilePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
        return url.URLByAppendingPathComponent("mapState").path!
    }
    
}