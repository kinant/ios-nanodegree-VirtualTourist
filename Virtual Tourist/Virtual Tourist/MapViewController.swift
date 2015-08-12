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
    
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var mapViewSuperView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    
    var inDeleteMode = false
    
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
        /*
        for pin in pins {
            println("\(pin.annotation.coordinate.latitude)")
            println("\(pin.annotation.coordinate.longitude)")
        }
        */
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
            mapView.addAnnotation(newAnnot)
        }
    }
    
    func addPin(location: CLLocationCoordinate2D){
        let annotation = VTAnnotation(coordinate: location, index: pinCount)
        mapView.addAnnotation(annotation)
        // setCenterOfMapToLocation(location)
        
        let newPin = Pin(annotation: annotation, context: sharedContext)
        
        pins.append(newPin)
        
        addAttractionsForPin(newPin)
        
        CoreDataStackManager.sharedInstance().saveContext()
        
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        
        //dispatch_async(dispatch_get_main_queue()){
            //dispatch_sync(queue){
                Flickr.sharedInstance().downloadImagePathsForPin(newPin, completionHandler: { (hasNoImages) -> Void in
                    println()
                })
            //}
        //}
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
        /*
        for view in views {
            var annotationView = view as! MKAnnotationView
            var endFrame = annotationView.frame
            
            annotationView.frame = CGRectOffset(endFrame, 0, -500)
            
            UIView.animateWithDuration(0.5, animations: {
                annotationView.frame = endFrame
            })
        }
        */
    }
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        if annotation is VTAnnotation {
            println("is VT annotation")
            let pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "myPin")
            // pinAnnotationView.draggable = true
            pinAnnotationView.canShowCallout = false
            // pinAnnotationView.animatesDrop = true
            pinAnnotationView.image = UIImage(named:"pin2")
            return pinAnnotationView
        } else if annotation is ATAnnotation {
            println("is AT annotation")
            let pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "atPin")
            pinAnnotationView.pinColor = MKPinAnnotationColor.Purple
            pinAnnotationView.canShowCallout = true
            // pinAnnotationView.animatesDrop = true
            pinAnnotationView.image = UIImage(named:"pin")
            return pinAnnotationView
        }
        return nil
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        var pinDetailVC = (segue.destinationViewController as! PinDetailViewController)
        
        if selectedPinIndex >= 0  {
            pinDetailVC.pin = pins[selectedPinIndex]
        }
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        println("annotation view selected!")
        
        if let selectedAnnotation = mapView.selectedAnnotations[0] as? VTAnnotation {
            
            selectedPinIndex = returnSelectedPinIndex(selectedAnnotation)
            
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
    
    func returnSelectedPinIndex(annotation: VTAnnotation) -> Int {
        
        println("pin count: \(pins.count)")
        for var i = 0; i < pins.count; i++ {
            // println("pin index: \(pin.index)")
            if pins[i].annotation == annotation {
                return i
            }
        }
        return -1
    }
    
    func mapView(mapView: MKMapView!, didDeselectAnnotationView view: MKAnnotationView!) {
        println("deselect!")
    }
    
    @IBAction func editButtonPressed(sender: UIBarButtonItem) {
        if sender.title == "Edit" {
            inDeleteMode = true
            sender.title = "Cancel"
            bottomView.hidden = false
            // mapViewSuperView.frame.origin.y -= bottomView.frame.height
        } else {
            inDeleteMode = false
            sender.title = "Edit"
            bottomView.hidden = true
            // mapViewSuperView.frame.origin.y += bottomView.frame.height
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}