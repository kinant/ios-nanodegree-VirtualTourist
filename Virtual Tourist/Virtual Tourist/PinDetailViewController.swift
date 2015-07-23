//
//  PinDetailViewController.swift
//  Virtual Turist
//
//  Created by Kinan Turjman on 7/22/15.
//  Copyright (c) 2015 Kinan Turman. All rights reserved.
//

import UIKit

class PinDetailViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    @IBOutlet weak var collectionView: UICollectionView?
    
    var pin: Pin!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 20, left: 10, bottom: 10, right: 10)
        layout.itemSize = CGSize(width: 90, height: 90)
        collectionView!.backgroundColor = UIColor.whiteColor()
        self.view.addSubview(collectionView!)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if pin.photos.isEmpty {
            
            Flickr.sharedInstance().searchPhotosByLatLon(pin, completionHandler: { (result, error) -> Void in
                if let photos = result {
                    
                    for photo in photos {
                        println(photo["url_m"])
                    }
                }
            })
        }
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 20
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionViewCell", forIndexPath: indexPath) as! CustomCollectionViewCell
        cell.backgroundColor = UIColor.blueColor()
        // cell.textLabel?.text = "\(indexPath.section):\(indexPath.row)"
        cell.title?.text = "\(indexPath.section):\(indexPath.row)"
        
        /*
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        
        dispatch_async(queue, {[weak self] in
            
            var image: UIImage?
            
            // download image
            dispatch_sync(queue, {

            })
            
            dispatch_sync(dispatch_get_main_queue(), {
                if let theImage = image {
                    // cell.image.image = theImage
                }
            })
        })
        */
        
        return cell
    }
}