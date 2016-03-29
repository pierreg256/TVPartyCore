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
    var files = [String]()
    
    let cachesPath = NSURL(fileURLWithPath:  NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true).last!, isDirectory:true)
    
    init(withPartyId id:String) {
        partyID = id
        updateLibrary()
    }
    
    @objc public func updateLibrary() {
        let s3 = AWSS3.defaultS3()
        let request = AWSS3ListObjectsRequest()
        request.bucket = AWS_USER_FILE_MANAGER_S3_BUCKET_NAME
        request.prefix = "\(partyID)/"
        
        do {
            try NSFileManager.defaultManager().createDirectoryAtURL(
                cachesPath.URLByAppendingPathComponent(partyID),
                withIntermediateDirectories: true,
                attributes: nil)
        } catch let error1  {
            print("Creating 'download' directory failed. Error: \(error1)")
        }
        
        s3.listObjects(request) { (output:AWSS3ListObjectsOutput?, error:NSError?) -> Void in
            if (error != nil) {
                print("error: \(error)")
            }
            let contents = output?.dictionaryValue["contents"] as! [AWSS3Object]
            for obj in contents {
                if let imageKey = obj.key where obj.key?.compare(request.prefix!) != NSComparisonResult.OrderedSame {

                    if (self.library[imageKey] == nil) {
                        let imagePath = self.cachesPath.URLByAppendingPathComponent(imageKey)
                        let downloadRequest = AWSS3TransferManagerDownloadRequest()
                        downloadRequest.bucket = AWS_USER_FILE_MANAGER_S3_BUCKET_NAME
                        downloadRequest.key = imageKey
                        downloadRequest.downloadingFileURL = imagePath

                        let transfer = AWSS3TransferUtility.defaultS3TransferUtility()
                        transfer.downloadToURL(imagePath, bucket: AWS_USER_FILE_MANAGER_S3_BUCKET_NAME, key: imageKey, expression: nil, completionHander: { (task:AWSS3TransferUtilityDownloadTask, url:NSURL?, data:NSData?, error:NSError?) in
                            if (error != nil) {
                                print("An error has occurred downloading the file : \(imageKey), with the following error : \(error!.description)")
                            } else {
                                self.library[imageKey] = self.cachesPath.URLByAppendingPathComponent(imageKey)
                                self.files.append(imageKey)
                                self.files.sortInPlace()
                                print("Cached : \(imageKey)")
                                
                            }
                        })
                    }
                }
            }
        }
        _ = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: #selector(ImageLibrary.updateLibrary), userInfo: nil, repeats: false)

    }
    
    func nextImage()->UIImage? {
        if (files.count>0) {
            if (curIndex > files.count-1) {
                curIndex = 0
            }
            let key = files[curIndex]
            if let data = NSData(contentsOfURL: library[key]!) {
                let image = UIImage(data: data)
                curIndex += 1
                return image
            }
            curIndex += 1
        }
        return nil
    }
    
}