//
//  MapViewController.swift
//  Virtual Turist
//
//  Created by Kinan Turjman on 7/22/15.
//  Copyright (c) 2015 Kinan Turman. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {

    var pins = [Pin]()
    var pinCount = 0
    var selectedPinIndex = 0
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        mapView.delegate = self
        mapView.mapType = .Standard
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self , action: "handleLongPress:")
        longPressGestureRecognizer.minimumPressDuration = 1.0
        self.mapView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    func handleLongPress(recognizer: UILongPressGestureRecognizer){
        println("long press!")
        if(recognizer.state == UIGestureRecognizerState.Began){
        
            var point = recognizer.locationInView(self.mapView)
            var locationCoordinate = self.mapView.convertPoint(point, toCoordinateFromView: self.mapView)
        
            addPin(locationCoordinate)
        }
    }
    
    func addPin(location: CLLocationCoordinate2D){
        let annotation = VTAnnotation(coordinate: location, index: pinCount)
        mapView.addAnnotation(annotation)
        setCenterOfMapToLocation(location)
        
        let newPin = Pin(annotation: annotation)
        
        pins.append(newPin)
        
        pinCount++
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
        selectedPinIndex = selectedAnnotation.index
        performSegueWithIdentifier("showPinDetail", sender: self)
        mapView.deselectAnnotation(selectedAnnotation , animated: true)
    }
    
    func mapView(mapView: MKMapView!, didDeselectAnnotationView view: MKAnnotationView!) {
        println("deselect!")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

