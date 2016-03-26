//
//  ViewController.swift
//  TVPartyCore
//
//  Created by Gilot, Pierre on 07/03/2016.
//  Copyright © 2016 Gilot, Pierre. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var cloudImages: InfiniteCarousel!
    let cloudDataSource = TVPartyCloudDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        cloudImages.dataSource = cloudDataSource
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

class ImageCell: UICollectionViewCell {
    static let ID = "ImageCell"
    @IBOutlet var imageView: UIImageView!
}


class TVPartyCloudDataSource: NSObject, UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10 // up to 17
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        NSLog("hi")
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ImageCell.ID, forIndexPath: indexPath) as! ImageCell
        let imageNumber = indexPath.item + 1
        let suffix = (imageNumber < 10) ? "0\(imageNumber)" : "\(imageNumber)"
        let image = UIImage(named: "IMG_\(suffix).jpg")
        cell.imageView.image = image
        return cell
    }
}