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

/* Class for the MapViewController */
class MapViewController: UIViewController, MKMapViewDelegate {

    // properties
    var pins = [Pin]() // array of pins
    var pinCount = 0 // the count of pins
    var selectedPinIndex = 0 // the index of the pin that was selected by user
    
    // outlet
    @IBOutlet weak var bottomView: UIView! // the bottom view shows up when deleting pins
    @IBOutlet weak var mapViewSuperView: UIView! // the superview for the mapview
    @IBOutlet weak var mapView: MKMapView! // the mapview
    @IBOutlet weak var hideAttractionsButton: UIButton! // a button that toggles whether attracions are shown or not
    
    var attractionsHidden = false // flag to determine if attractions are hidden or not
    var inDeleteMode = false // flag to determine if we are in editing or delete mode
    
    var annotationToAdd: VTAnnotation! // will store the annotation to be added
    
    // MARK: - Core Data Convenience. This will be useful for fetching. And for adding and saving objects as well.
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set the mapview properties
        mapView.delegate = self
        mapView.mapType = .Standard
        mapView.userInteractionEnabled = true
        
        // load region from user defaults
        let defaults = NSUserDefaults.standardUserDefaults()
        
        // get saved data
        let latitude = defaults.doubleForKey("latitude")
        let longitude = defaults.doubleForKey("longitude")
        let spanLatDelta = defaults.doubleForKey("spanLatDelta")
        let spanLongDelta = defaults.doubleForKey("spanLongDelta")
        
        // create span and region based on the data retrieved
        let span = MKCoordinateSpan(latitudeDelta: spanLatDelta, longitudeDelta: spanLongDelta)
        let region = MKCoordinateRegion(center: CLLocationCoordinate2DMake(latitude, longitude), span: span)
        
        // check that latitude and longitude are not 0.0
        // if they are then no user defaults have been saved
        if latitude != 0.0 && longitude != 0.0 {
            // set the region
            mapView.setRegion(region, animated: false)
        }
        
        // add the long press gesture recognizer for adding pins
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self , action: "handleLongPress:")
        longPressGestureRecognizer.minimumPressDuration = 1.0
        self.mapView.addGestureRecognizer(longPressGestureRecognizer)

        // fetch any previously saved pins
        pins = fetchAllPins()
        
        // set the pin count
        pinCount = pins.count
        
        // add previously saved pins to the map
        addPins()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        // Whenever the view appears, we check if the pin's images are all downloaded
        // If they are not, we show activity indicator and start the fetching of images
        
        // check that the pins array is not empty
        if pins.isEmpty == false {
            
            // for each pin
            for pin in pins {
                
                // check if all photos have been downloaded
                if pin.allPhotosDownloaded() == false {
                    
                    // all photos not downloaded
                    // show the activity indicator
                    showPinActivityIndicator(pin)
                    changePinActivityIndicator(pin)
                    
                    // fetch the images
                    Flickr.sharedInstance().fetchImagesForPin(pin, completionHandler: { (success) -> Void in
                        // hide indicator when fetching complete
                        self.hidePinActivityIndicator(pin)
                    })
                }
            }
        }
    }
    
    /*
     * This function handles the long press
    */
    func handleLongPress(recognizer: UILongPressGestureRecognizer){
        
        // obtain the point where the long press was made in the mapview
        var point = recognizer.locationInView(self.mapView)
        
        // convert this point into a coordinate
        var locationCoordinate = self.mapView.convertPoint(point, toCoordinateFromView: self.mapView)
        
        // for convinience, we define the current pin as the pin given by the pins array with
        // the current pincount as index
        var currentPin: Pin {
            get {
                return pins[pinCount]
            }
        }
        
        // check that we are not in delete mode (to add a pin)
        if !inDeleteMode {
            
            // if we have begun the gesture, then we start to add the pin
            if(recognizer.state == UIGestureRecognizerState.Began){
                
                // add the pin
                addPin(locationCoordinate)
            
            }
            // pin is draggable, so if the finger is moved, then the state changes to .Changed
            else if (recognizer.state == UIGestureRecognizerState.Changed){
                
                // the pin has been moved, so we set the annotation-being-added's coordinates to the new location
                self.annotationToAdd.setNewCoordinate(locationCoordinate)
                
                // modify the lat and long for the pin that we are adding (index is the current pinCount)
                currentPin.latitude = locationCoordinate.latitude
                currentPin.longitude = locationCoordinate.longitude
            
            }
            // once we are done dragging the pin, the state changes to .Ended
            else if recognizer.state == .Ended {
                
                // make sure that we have set an annotation to be added
                if annotationToAdd != nil {
                    
                    // get the annotation view for the annotation being added
                    var annotationView = mapView.viewForAnnotation(annotationToAdd)
                
                    // change the pin's annotation image so that it shows the placed pin
                    dispatch_async(dispatch_get_main_queue()){
                        annotationView.image = UIImage(named: "pin2")
                    }
                    
                    // complete the process of adding the pin
                    self.addPinComplete(currentPin)
                    
                    annotationToAdd = nil
                }
            }
        }
    }
    
    /*
    * This function adds all the pins in the pins array to the map view
    */
    func addPins(){
        
        // iterate over each pin
        for pin in pins {
            
            // create the annotation
            let annotation = VTAnnotation(coordinate: CLLocationCoordinate2DMake(pin.latitude, pin.longitude))
            
            // pin annotations are not persisted, so we set it
            pin.annotation = annotation
            
            // add the annotation to the map
            mapView.addAnnotation(annotation)
            
            // add attractions
            // iterate over each attraction for the pin
            for attraction in pin.attractions {
                // add it to the map
                mapView.addAnnotation(attraction.annotation)
            }
        }
    }
    
    /*
    * This adds the attracions for a pin. It calls TIXIK API to obtain the attractions data.
    */
    func addAttractionsForPin(pin: Pin){
        
        // obtain the location of the pin
        var location = pin.annotation.coordinate
        
        // get the dictionary of attractions from the TIXIK API
        var attractions = Tixik.sharedInstance().taskForData(location)
        
        // iterate over each attraction
        for attraction in attractions {
            
            // set variables for name, x and y
            let name = attraction["name"] as! String
            let x = attraction["x"] as! Double
            let y = attraction["y"] as! Double
            
            // create a new Attraction Annotation
            let newAnnot = ATAnnotation(coordinate: CLLocationCoordinate2DMake(x, y), title: name)
            
            // create a new attraction
            let newAttraction = Attraction(annotation: newAnnot, context: sharedContext)
            
            // set the attraction's pin
            newAttraction.pin = pin
            
            // check that the attractions are not being hidden
            if !attractionsHidden {
                // if not hidden, add the attraction to the map
                dispatch_async(dispatch_get_main_queue()){
                    self.mapView.addAnnotation(newAnnot)
                }
            }
        }
        
        // change the pin's activity indicator so that it now shows the photo download in progress in the indicator
        changePinActivityIndicator(pin)
        
        // save the context
        dispatch_async(dispatch_get_main_queue()){
            self.saveContext()
        }
    }
    
    /*
     * This helper function returns a VTPinAnnotationView for a given pin
    */
    func annotationViewForPin(pin: Pin) -> VTPinAnnotationView {
        return mapView.viewForAnnotation(pin.annotation) as! VTPinAnnotationView
    }
    
    /*
    * Show the pin's activity indicator
    */
    func showPinActivityIndicator(pin: Pin){
        annotationViewForPin(pin).showActivityIndicator()
    }
    
    /*
    * Change the pin's activity indicator (it will now show a camera as the background)
    */
    func changePinActivityIndicator(pin:Pin){
        annotationViewForPin(pin).showPhotoInActivityIndicator()
    }
    
    /*
    * Hide the pin's activity indicator
    */
    func hidePinActivityIndicator(pin: Pin){
        annotationViewForPin(pin).hideActivityIndicator()
    }
    
    /*
    * Adds a pin to the map. The pin is draggable, so the pin is not completely added. addPinComplete handles this.
    */
    func addPin(location: CLLocationCoordinate2D){
        
        // create a new VTAnnotation and add it to the map
        // this annotation will have an image of a floating pin
        let annotation = VTAnnotation(coordinate: location)
        mapView.addAnnotation(annotation)
        
        // create the new pin
        let newPin = Pin(annotation: annotation, context: sharedContext)
        
        // append the pin to the pins array
        pins.append(newPin)
        
        // set the annotation to add
        self.annotationToAdd = annotation
    }
    
    /*
    * Once the pin is dragged into place and released, we can complete the addition of the pin
    */
    func addPinComplete(newPin: Pin){
        
        // set the pin's download task in progress to true. Other parts of the app check if the
        // data is currently being downloaded for the pin (so that we don't start a task again)
        newPin.downloadTaskInProgress = true
        
        // show the pin's activity indicator (displays an activity indicator with the eiffel tower as background)
        showPinActivityIndicator(newPin)
        
        // pre-fetch the data
        
        // first we get all the image paths
        Flickr.sharedInstance().downloadImagePathsForPin(newPin, completionHandler: { (hasNoImages) -> Void in
            
            // reset the flag
            newPin.downloadTaskInProgress = false
            
            // add the attractions for the pin
            self.addAttractionsForPin(newPin)
            
            // check if the pin has no images
            if hasNoImages {
                // hide activity indicator
                self.hidePinActivityIndicator(newPin)
            } else {
                // pin has images, so we start to download them now...
                Flickr.sharedInstance().fetchImagesForPin(newPin, completionHandler: { (success) -> Void in
                // if success {
                    // once all images are downloaded, the completion handler will be called in fetchImagesForPin
                    // hide the activity indicator
                    self.hidePinActivityIndicator(newPin)
                //}
                })
            }
        })
        
        // increment the pin count
        pinCount++
    }
    
    func saveContext(){
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    /*
     * This method fetches all the pins from the shared context (what we have saved)
     * Returns the array of pins
    */
    func fetchAllPins() -> [Pin] {
        
        // create and execute the fetch request
        let error: NSErrorPointer = nil
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        let results = sharedContext.executeFetchRequest(fetchRequest, error: error)
        
        // check for errors
        if error != nil {
            println("Error in fetchAllActors(): \(error)")
        }
        // return the results as an array of pins
        return results as! [Pin]
    }
    
    /*
    * mapView Delegate function that is called when the region displayed changes.
    * We use is to determine when the user has moved, pinched or zoomed the map.
    * We save the region
    */
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        
        // we save the information into the user defaults
        let defaults = NSUserDefaults.standardUserDefaults()
        
        // obtain the values
        let latitude = mapView.region.center.latitude
        let longitude = mapView.region.center.longitude
        let spanLatDelta = mapView.region.span.latitudeDelta
        let spanLongDelta = mapView.region.span.longitudeDelta
        
        // save them
        defaults.setDouble(latitude, forKey: "latitude")
        defaults.setDouble(longitude, forKey: "longitude")
        defaults.setDouble(spanLatDelta, forKey: "spanLatDelta")
        defaults.setDouble(spanLongDelta, forKey: "spanLongDelta")
    }
    
    /*
    * mapView delegate function that is called when an annotation view is added
    * We use this so that the app can animate our pins being added
    * http://stackoverflow.com/questions/6808876/how-do-i-animate-mkannotationview-drop
    */
    func mapView(mapView: MKMapView!, didAddAnnotationViews views: [AnyObject]!) {
        
        // iterate over each view
        for view in views {
            var annotationView = view as! MKAnnotationView
            
            // the end frame (for the animation)
            var endFrame = annotationView.frame
            
            // set the annotation's view frame with a vertical offset
            annotationView.frame = CGRectOffset(endFrame, 0, -500)
            
            // animate the change in frame (ie the pin being dropped)
            UIView.animateWithDuration(0.5, animations: {
                annotationView.frame = endFrame
            })
        }
    }
    
    /*
     * mapView delegate function returns the view for an annotation
    */
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        // first we check if the annotation is a normal pin (VTAnnotation)
        // or an attraction pin (ATAnnotation)
        if annotation is VTAnnotation {
            
            // create a new VTPinAnnotationView (custom MKPinAnnotationView)
            let pinAnnotationView = VTPinAnnotationView(annotation: annotation, reuseIdentifier: "myPin")
            
            // set properties
            pinAnnotationView.canShowCallout = false
            pinAnnotationView.image = UIImage(named: "pin2")
            
            // if we are adding a new pin, then the annotation to add will not be nil
            if annotationToAdd != nil {
                // we then want to display the pin as a floating pin
                pinAnnotationView.image = UIImage(named:"floating_pin")
            }
            
            return pinAnnotationView
            
        }
        // else, the pin is an attraction pin
        else if annotation is ATAnnotation {
            let pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "atPin")
            pinAnnotationView.canShowCallout = true
            pinAnnotationView.image = UIImage(named:"pin")
            return pinAnnotationView
        }
        return nil
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        var pinDetailVC = (segue.destinationViewController as! PinDetailViewController)
        
        // check that the selected pin's index is greater than 0
        // (it is -1 for invalid pins)
        if selectedPinIndex >= 0  {
            
            // obtain the selected pin
            let selectedPin = pins[selectedPinIndex]
            
            // set the pin for the pin detail view controller
            pinDetailVC.pin = selectedPin
            
            // if the pin has no photos and if it has no download task in progress, we proceed to fetch it's images
            // this is the case, for example, when we delete all the photos in a collection and then return
            // to the mapview
            if selectedPin.photos.count == 0 && !selectedPin.downloadTaskInProgress {
                pinDetailVC.fetchCollection()
            }
        }
    }
    
    /*
     * mapView delegate function for selecting a pin
    */
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        
        // we make sure that the selected annotation is a VTAnnotation (so not an attraction)
        if let selectedAnnotation = mapView.selectedAnnotations[0] as? VTAnnotation {
            
            // we obtain the index of the selected annotation
            selectedPinIndex = returnSelectedPinIndex(selectedAnnotation)
            
            // if we are in delete mode, we delete the pin
            if inDeleteMode {
                deletePin(pins[selectedPinIndex])
            } else {
                // if we are not in delete mode, we perform the segue to show
                // the pin detail view controller
                performSegueWithIdentifier("showPinDetail", sender: self)
            }
            
            // we only want to select a pin at a time, so we deselect it
            mapView.deselectAnnotation(selectedAnnotation , animated: true)
        }
    }
    
    /*
     * This method deletes a pin
    */
    func deletePin(pin: Pin) {
        
        // first we remove the pin, which happens to be the first item in the selected annotations array
        // for the map view
        mapView.removeAnnotation(mapView.selectedAnnotations[0] as? VTAnnotation)
        
        // we proceed to delete all the attractions for this pin
        deleteAttractionsForPin(pin)
        
        // delete the pin from the context and save
        sharedContext.deleteObject(pin)
        sharedContext.save(nil)
    }
    
    /*
    * This method deletes all the attractions for a pin
    */
    func deleteAttractionsForPin(pin: Pin){
        
        // iterate over each attraction in the pin
        for var i = 0; i < pin.attractions.count; i++ {
            
            // iterate over each annotation in the mapview
            for var j = 0; j < mapView.annotations.count; j++ {
                
                // check if the annotation is for an attraction
                if let attraction = mapView.annotations[j] as? ATAnnotation {
                    
                    // check if the pin's attraction is equal to the mapview's attraction
                    if pin.attractions[i].annotation == attraction {
                        
                        // if so, the attraction belongs to this pin, so we delete it
                        mapView.removeAnnotation(attraction)
                    }
                }
            }
        }
    }
    
    /*
    * Hides all the attractions on the map
    */
    func hideAttractions() {
        
        // remove all attractions from all pins
        for pin in pins {
            deleteAttractionsForPin(pin)
        }
        // set the flag
        attractionsHidden = true
    }
    
    /*
    * Shows all the attractions on the map
    */
    func showAttractions() {
        
        // iterate over each pin
        for pin in pins {
            // iterate over each attraction
            for attraction in pin.attractions {
                // add the attraction to the map
                mapView.addAnnotation(attraction.annotation)
            }
        }
        // reset the flag
        attractionsHidden = false
    }
    
    /*
    * This function returns the index for a given pin in the pins array based on the
    * annotation that is provided in the argument. When we select a pin in the
    * map view, we select an annotation, not a pin. This function helps us determine
    * what pin we selected based on the selected annotation.
    *
    */
    func returnSelectedPinIndex(annotation: VTAnnotation) -> Int {
        
        // iterate over each pin
        for var i = 0; i < pins.count; i++ {
            
            // if the pin's annotation is equal to the desired annotation, return the index
            if pins[i].annotation == annotation {
                return i
            }
        }
        // if the annotation is not found, then return -1
        return -1
    }
    
    /*
    * Handle's the edit button being pressed. When we press edit, we can delete pins.
    */
    @IBAction func editButtonPressed(sender: UIBarButtonItem) {
        
        // check what mode we are in
        if sender.title == "Edit" {
            
            // set the delete mode flag
            inDeleteMode = true
            
            // change the button title
            sender.title = "Cancel"
            
            // show the bottom view and shift the mapview
            bottomView.hidden = false
            mapViewSuperView.bounds.origin.y += bottomView.frame.height
        
        } else {
            
            // in delete mode, so we revert
            inDeleteMode = false
            
            // reset the title
            sender.title = "Edit"
            
            // hide and reset the mapview
            bottomView.hidden = true
            mapViewSuperView.bounds.origin.y -= bottomView.frame.height
        }
    }
    
    /*
    * Handles the hide/show attractions button being pressed.
    * Attractions can be annoying sometimes, so the user has
    * the option to toggle their view
    */
    @IBAction func hideAttractions(sender: UIButton) {
        
        // check if we are hiding or showing
        if sender.titleLabel?.text == "HIDE ATTRACTIONS" {
            
            // set the title
            sender.setTitle("SHOW ATTRACTIONS", forState: .Normal)
            
            // hide the attractions
            hideAttractions()
        } else {
            
            // set the title
            sender.setTitle("HIDE ATTRACTIONS", forState: .Normal)
            
            // show attractions
            showAttractions()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}