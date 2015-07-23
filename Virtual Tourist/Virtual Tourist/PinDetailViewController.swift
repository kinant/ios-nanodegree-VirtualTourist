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
                        if let imageURL = photo["url_m"] as? String {
                            let newPhoto = Photo(imagePath: imageURL)
                            println(newPhoto.imagePath!)
                            self.pin.photos.append(newPhoto)
                        }
                    }
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.collectionView?.reloadData()
                }
            })
        }
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if pin.photos.count > 22 {
            return 21
        } else {
            return pin.photos.count
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let photo = pin.photos[indexPath.row]
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionViewCell", forIndexPath: indexPath) as! CustomCollectionViewCell
        cell.backgroundColor = UIColor.blueColor()
        // cell.textLabel?.text = "\(indexPath.section):\(indexPath.row)"
        cell.title?.text = "\(indexPath.section):\(indexPath.row)"
        cell.image!.image = nil
        
        var posterImage = UIImage(named: "posterPlaceHoldr")
        
        if photo.posterImage != nil {
            println("photo has image!")
            posterImage = photo.posterImage
            cell.image!.image = posterImage
        }
            
        else {
            let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        
            dispatch_async(queue, {[weak self] in
            
                var image: UIImage?
            
                // download image
                dispatch_sync(queue, {
                    Flickr.sharedInstance().downloadRandomImageForPin(self!.pin, completionHandler: { (imageData) -> Void in
                        image = UIImage(data: imageData!)
                    })
                })
            
                dispatch_sync(dispatch_get_main_queue(), {
                    if let theImage = image {
                        photo.posterImage = theImage
                        cell.image.image = theImage
                    }
                })
            })
        }
        
        return cell
    }
}