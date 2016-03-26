//
//  ImageLibrary.swift
//  TVPartyCore
//
//  Created by Pierre Gilot on 26/03/2016.
//  Copyright © 2016 Gilot, Pierre. All rights reserved.
//

import Foundation
import UIKit

public class ImageLibrary {
    var partyID:String
    var curIndex = 0
    var library = [String:NSURL]()
    
    let cachesPath = NSURL(string:NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true).last!)
    
    init(withPartyId id:String) {
        partyID = id
        updateLibrary()
    }
    
    @objc public func updateLibrary() {
        let s3 = AWSS3.defaultS3()
        let request = AWSS3ListObjectsRequest()
        request.bucket = AWS_USER_FILE_MANAGER_S3_BUCKET_NAME
        request.prefix = "\(partyID)/"
        
        s3.listObjects(request) { (output:AWSS3ListObjectsOutput?, error:NSError?) -> Void in
            if (error != nil) {
                print("error: \(error)")
            }
            let contents = output?.dictionaryValue["contents"] as! [AWSS3Object]
            for obj in contents {
                if let imageKey = obj.key where obj.key?.compare(request.prefix!) != NSComparisonResult.OrderedSame {
                    print(imageKey)
                    if (self.library[imageKey] == nil) {
                        self.library[imageKey] = self.cachesPath?.URLByAppendingPathComponent(imageKey)
                        print(self.library[imageKey]?.absoluteString)
                    }
                }
            }
        }
        _ = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: #selector(ImageLibrary.updateLibrary), userInfo: nil, repeats: false)

    }
    
}