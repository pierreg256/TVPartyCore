//
//  LoginViewController.swift
//  TVPartyCore
//
//  Created by Gilot, Pierre on 21/03/2016.
//  Copyright © 2016 Gilot, Pierre. All rights reserved.
//

import Foundation
import UIKit

import FBSDKCoreKit
import FBSDKTVOSKit


public class LoginViewController : UIViewController, FBSDKDeviceLoginButtonDelegate {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var loginButton: FBSDKDeviceLoginButton!
    var _blankImage: UIImage!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        loginButton.readPermissions = ["email"]
        loginButton.delegate = self
        _blankImage = self.imageView.image
        
        // Subscribe to FB session changes (in case they logged in or out in the second tab)
        NSNotificationCenter.defaultCenter().addObserverForName(
            FBSDKAccessTokenDidChangeNotification,
            object: nil,
            queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
                self._updateContent()
        }
        
        // If the user is already logged in.
        if (FBSDKAccessToken.currentAccessToken() != nil) {
            _updateContent()
        }

    }
    
    //MARK: Application methods
    func _flipImageViewToImage(image: UIImage) {
        UIView.transitionWithView(self.imageView,
            duration: 1,
            options:.TransitionFlipFromLeft,
            animations: { () -> Void in
                self.imageView.image = image
            }, completion: nil)
    }
    
    func _updateContent() {
        if (self.imageView.image == _blankImage) {
            // Download the user's profile image. Usually Facebook Graph API
            // should be accessed via `FBSDKGraphRequest` except for binary data (like the image).
            let urlString = String(
                format: "https://graph.facebook.com/v2.5/me/picture?type=square&width=%d&height=%d&access_token=%@",
                Int(self.imageView.bounds.size.width),
                Int(self.imageView.bounds.size.height),
                FBSDKAccessToken.currentAccessToken().tokenString)
            
            let url = NSURL(string: urlString)
            let userImage = UIImage(data: NSData(contentsOfURL: url!)!)
            _flipImageViewToImage(userImage!)
        }
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.USEast1,
            identityPoolId:AMAZON_COGNITO_IDENTITY_POOL_ID)
        let token = FBSDKAccessToken.currentAccessToken().tokenString
        credentialsProvider.logins = [AWSCognitoLoginProviderKey.Facebook.rawValue: token]
        let configuration = AWSServiceConfiguration(region:.USEast1, credentialsProvider:credentialsProvider)
        
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration

        print("Identity id : \(credentialsProvider.identityId)")
        
        let s3 = AWSS3.defaultS3()
        let request = AWSS3ListObjectsRequest()
        request.bucket = AWS_USER_FILE_MANAGER_S3_BUCKET_NAME
        request.prefix = "\(credentialsProvider.identityId)/"
        s3.listObjects(request) { (output:AWSS3ListObjectsOutput?, error:NSError?) -> Void in
            print("error: \(error)")
            print(output)
        }

        let transferUtility = AWSS3TransferUtility.defaultS3TransferUtility()
        transferUtility.downloadDataFromBucket(AWS_USER_FILE_MANAGER_S3_BUCKET_NAME, key: "maclef", expression: nil) { (task:AWSS3TransferUtilityDownloadTask , url:NSURL?, data:NSData?, error:NSError?) -> Void in
            print("error : \(error)")
            print("task \(task)")
            print("url \(url)")
            print(String(data: data!, encoding: NSUTF8StringEncoding))
            print ("hello")
        }
        
        let analytics = AWSMobileAnalytics(forAppId: AMAZON_MOBILE_ANALYTICS_APP_ID, identityPoolId: AMAZON_COGNITO_IDENTITY_POOL_ID)
        dispatch_async(dispatch_get_main_queue()) { [unowned self] in
            self.performSegueWithIdentifier("showImages", sender: self)
        }
    }
    
    //MARK: prepare for segue
    public override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        print("Following segue: \(segue.identifier)")
    }
    
    //MARK: FBSDKDeviceLoginButtonDelegate
    
    public func deviceLoginButtonDidCancel(button: FBSDKDeviceLoginButton) {
        print("Login cancelled");
    }
    
    public func deviceLoginButtonDidLogIn(button: FBSDKDeviceLoginButton) {
        print("Login complete");
        _updateContent()
    }
    
    public func deviceLoginButtonDidLogOut(button: FBSDKDeviceLoginButton) {
        print("Logout complete");
        _flipImageViewToImage(_blankImage);
    }
    
    public func deviceLoginButtonDidFail(button: FBSDKDeviceLoginButton, error: NSError) {
        print("Login error : %@", error)
    }
    
}