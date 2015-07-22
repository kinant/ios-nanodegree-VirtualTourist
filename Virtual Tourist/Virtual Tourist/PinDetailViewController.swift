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
        
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        
        dispatch_async(queue, {[weak self] in
            
            var image: UIImage?
            
            // download image
            dispatch_sync(queue, {
                let randomPhotoIndex = Int(arc4random_uniform(UInt32(dataPhotosArray.count)))
                let photoDictionary = dataPhotosArray[randomPhotoIndex] as [String: AnyObject]
                
                let photoTitle = photoDictionary["title"] as? String
                let imageUrlString = photoDictionary["url_m"] as? String
                let imageURL = NSURL(string: imageUrlString!)
                let urlRequest = NSURLRequest(URL: imageURL!)
                var downloadError: NSError?
                
                let imageData = NSURLConnection.sendSynchronousRequest(urlRequest, returningResponse: nil, error: &downloadError)
                
                if let error = downloadError {
                    println("error downloading image")
                } else {
                    if imageData!.length > 0 {
                        image = UIImage(data: imageData!)
                    } else {
                        println("No data could get downloaded from the URL")
                    }
                }
            })
            
            dispatch_sync(dispatch_get_main_queue(), {
                if let theImage = image {
                    cell.image.image = theImage
                }
            })
        })
        
        return cell
    }
}