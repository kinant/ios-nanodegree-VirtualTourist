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
    
    @IBOutlet weak var mapView: MKMapView!
    
    lazy var sharedContext = {
        CoreDataStackManager.sharedInstance().managedObjectContext!
        }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        mapView.delegate = self
        mapView.mapType = .Standard
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self , action: "handleLongPress:")
        longPressGestureRecognizer.minimumPressDuration = 1.0
        self.mapView.addGestureRecognizer(longPressGestureRecognizer)
        
        pins = fetchAllPins()
        
        pinCount = pins.count
        
        for pin in pins {
            println("\(pin.annotation.coordinate.latitude)")
            println("\(pin.annotation.coordinate.longitude)")
        }
        
        addPins()
    }
    
    func handleLongPress(recognizer: UILongPressGestureRecognizer){
        println("long press!")
        if(recognizer.state == UIGestureRecognizerState.Began){
        
            var point = recognizer.locationInView(self.mapView)
            var locationCoordinate = self.mapView.convertPoint(point, toCoordinateFromView: self.mapView)
        
            addPin(locationCoordinate)
        }
    }
    
    func addPins(){
        for pin in pins {
            mapView.addAnnotation(pin.annotation)
            pin.annotation.index = pin.index
        }
    }
    
    func addAttractionsAtLocation(location: CLLocationCoordinate2D){
        var attractions = Tixik.sharedInstance().taskForData(location)
        
        println("COUNT: \(attractions.count)")
        
        for attraction in attractions {
            
            var name = attraction["name"] as! String
            var x = attraction["x"] as! Double
            var y = attraction["y"] as! Double
            
            var newAnnot = VTAnnotation(coordinate: CLLocationCoordinate2DMake(x, y), index: -2)
            mapView.addAnnotation(newAnnot)
        }
        
    }
    
    func addPin(location: CLLocationCoordinate2D){
        let annotation = VTAnnotation(coordinate: location, index: pinCount)
        mapView.addAnnotation(annotation)
        setCenterOfMapToLocation(location)
        
        let newPin = Pin(annotation: annotation, index: annotation.index, context: sharedContext)
        
        pins.append(newPin)
        
        addAttractionsAtLocation(location)
        
        CoreDataStackManager.sharedInstance().saveContext()
        
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        
        dispatch_async(dispatch_get_main_queue()){
        // prefetch the images
            // let mainQueue = NSOperationQueue.
            dispatch_sync(queue){
                Flickr.sharedInstance().downloadImagePathsForPin(newPin)
            }
            dispatch_sync(queue){
                // Flickr.sharedInstance().fetchImagesForPin(newPin)
            }
        }
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
            let pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "myPin")
            pinAnnotationView.draggable = true
            pinAnnotationView.canShowCallout = false
            return pinAnnotationView
        }
        return nil
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        var pinDetailVC = (segue.destinationViewController as! PinDetailViewController)
        pinDetailVC.pin = pins[selectedPinIndex]
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        println("annotation view selected!")
        var selectedAnnotation = mapView.selectedAnnotations[0] as! VTAnnotation
        selectedPinIndex = returnSelectedPinIndex(selectedAnnotation)
        println("selected pin: \(selectedPinIndex)")
        performSegueWithIdentifier("showPinDetail", sender: self)
        mapView.deselectAnnotation(selectedAnnotation , animated: true)
    }
    
    func returnSelectedPinIndex(annotation: VTAnnotation) -> Int {
        
        println("pin count: \(pins.count)")
        for pin in pins {
            println("pin index: \(pin.index)")
            
            if pin.annotation == annotation {
                return pin.index
            }
        }
        return -1
    }
    
    func mapView(mapView: MKMapView!, didDeselectAnnotationView view: MKAnnotationView!) {
        println("deselect!")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}