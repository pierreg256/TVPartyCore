//
//  SlideshowViewController.swift
//  TVPartyCore
//
//  Created by Gilot, Pierre on 21/03/2016.
//  Copyright © 2016 Gilot, Pierre. All rights reserved.
//

import Foundation
import UIKit
import SceneKit

public class SlideshowViewController : UIViewController {
    let DEFAULT_YFOV = CGFloat(60.0)
    let DEFAULT_CAMERA_DEPTH = Float(20)
    let DEFAULT_MAX_PHOTOS = 10
    let DEFAULT_PHOTO_SIZE = 4.0
    
    var sceneView: SCNView!
    var camera: SCNNode!
    var ground: SCNNode!
    var light: SCNNode!
    var images = [UIImage]()
    var timer:NSTimer?
    var curPhotoIndex=0
    var curPhotoNumber=0
    
    private func maxXforDepth(depth:CGFloat) -> CGFloat {
        let xFov = DEFAULT_YFOV * sceneView.frame.width / sceneView.frame.height
        
        let computedDepth = CGFloat(DEFAULT_CAMERA_DEPTH - Float(depth))
        let maxX = computedDepth * tan(xFov/2.0*CGFloat(M_PI)/180.0)
        
        //print("computed xFov : \(xFov), Depth: \(computedDepth), maxX : \(maxX)")
        return maxX
    }
    
    private func shiftLeft(node:SCNNode){
        // find the slide left dimension
        let maxX = self.maxXforDepth(CGFloat(node.position.z))
        let xPos = CGFloat(node.position.x)
        let xMove = maxX + xPos
        
        node.runAction(SCNAction.moveByX(-xMove, y: 0, z: 0, duration: Double(xMove))) { () -> Void in
            print("Je suis sorti: \(node.position), \(self.curPhotoNumber)")
            node.position.x = Float(maxX) + Float(2.0 * self.DEFAULT_PHOTO_SIZE)
            //node.position = SCNVector3(x: Float(maxX), y: Float(arc4random_uniform(6))+4, z: Float(arc4random_uniform(30))-15)
            self.shiftLeft(node)
        }
    }
    
    func emitNextPhoto() {
        if (images.count>0){
            let image = images[curPhotoIndex]
            
            var width=CGFloat(DEFAULT_PHOTO_SIZE)
            var height=CGFloat(DEFAULT_PHOTO_SIZE)
            if (image.size.height > image.size.width) {
                height = height * image.size.height / image.size.width
            } else {
                width = width * image.size.width / image.size.height
            }
            let planeGeometry =  SCNPlane(width: width , height: height)
            let planeMaterial = SCNMaterial()
            planeMaterial.diffuse.contents = image //UIImage(named: "IMG_0\(i).jpg")//UIColor.redColor()
            planeMaterial.doubleSided=true
            planeGeometry.materials = [planeMaterial]
            let plane = SCNNode(geometry: planeGeometry)
            let randomZ = Float(arc4random_uniform(30))-15
            let maxX = maxXforDepth(CGFloat(randomZ))
            plane.position = SCNVector3(x: Float(maxX), y: Float(arc4random_uniform(4))+4, z: randomZ)
            plane.eulerAngles.x = Float(-M_PI_4/4)
            //plane.runAction(SCNAction.rotateByX(0, y: 0.5, z: 0, duration: 1))
            shiftLeft(plane)
            sceneView.scene?.rootNode.addChildNode(plane)

            curPhotoIndex++
            if (curPhotoIndex>=images.count) {
                curPhotoIndex = 0
            }
            curPhotoNumber++
        }
        if (curPhotoNumber>DEFAULT_MAX_PHOTOS) {
            timer?.invalidate()
        }
    }
    
    private func setup(withAnmiation animation:Bool) {
        sceneView = SCNView(frame: self.view.frame)
        sceneView.scene = SCNScene()
        sceneView.backgroundColor = UIColor.darkGrayColor()
        sceneView.showsStatistics = true
        self.view.addSubview(sceneView)
        
        let groundGeometry = SCNFloor()
        groundGeometry.reflectivity = 0.25
        let groundMaterial = SCNMaterial()
        groundMaterial.diffuse.contents = UIColor.darkGrayColor()
        groundGeometry.materials = [groundMaterial]
        ground = SCNNode(geometry: groundGeometry)
        
        let camera = SCNCamera()
        camera.zFar = 10000
        camera.yFov = Double(DEFAULT_YFOV)
        self.camera = SCNNode()
        self.camera.camera = camera
        self.camera.position = SCNVector3(x: 0, y: 0, z: DEFAULT_CAMERA_DEPTH)

        let constraint = SCNLookAtConstraint(target: ground)
        constraint.gimbalLockEnabled = true
        let cameraOrbit = SCNNode()
        cameraOrbit.addChildNode(self.camera)
        cameraOrbit.eulerAngles.x = Float(-M_PI_4/4)
        
        let ambientLight = SCNLight()
        ambientLight.color = UIColor.darkGrayColor()
        ambientLight.type = SCNLightTypeAmbient
        self.camera.light = ambientLight
        
        if (animation) {
            let moveRight = SCNAction.rotateByX(0, y: 0.5, z: 0, duration: 1)
            let cameraRotation = SCNAction.repeatActionForever(SCNAction.sequence([moveRight]))
            cameraOrbit.runAction(cameraRotation)
        }
        
        let spotLight = SCNLight()
        spotLight.type = SCNLightTypeSpot
        spotLight.castsShadow = true
        spotLight.spotInnerAngle = 70.0
        spotLight.spotOuterAngle = 90.0
        spotLight.zFar = 500
        light = SCNNode()
        light.light = spotLight
        light.position = SCNVector3(x: 0, y: 25, z: 25)
        light.constraints = [constraint]
        
        sceneView.scene?.rootNode.addChildNode(cameraOrbit)
        sceneView.scene?.rootNode.addChildNode(ground)
        sceneView.scene?.rootNode.addChildNode(light)
        
        // go fetch the images
        for (var i=1; i<5; i++){
            images.append(UIImage(named: "IMG_0\(i).jpg")!)
        }
        
        // Start the photo emitter
        timer = NSTimer.scheduledTimerWithTimeInterval( 5, target: self, selector: Selector("emitNextPhoto"), userInfo: nil, repeats: true)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        setup(withAnmiation: false)
        
        /*
        for (var i=1;i<5;i++){
            let image = UIImage(named: "IMG_0\(i).jpg")
            var width=CGFloat(8)
            var height=CGFloat(8)
            if (image?.size.height > image?.size.width) {
                height = height * image!.size.height / image!.size.width
            } else {
                width = width * image!.size.width / image!.size.height
            }
            let planeGeometry =  SCNPlane(width: width , height: height)
            let planeMaterial = SCNMaterial()
            planeMaterial.diffuse.contents = image //UIImage(named: "IMG_0\(i).jpg")//UIColor.redColor()
            planeMaterial.doubleSided=true
            planeGeometry.materials = [planeMaterial]
            let plane = SCNNode(geometry: planeGeometry)
            plane.position = SCNVector3(x: Float(arc4random_uniform(30))-15, y: Float(arc4random_uniform(6))+4, z: Float(arc4random_uniform(30))-15)
            plane.eulerAngles.x = Float(-M_PI_4/4)
            //plane.runAction(SCNAction.rotateByX(0, y: 0.5, z: 0, duration: 1))
            shiftLeft(plane)
            sceneView.scene?.rootNode.addChildNode(plane)
        }
        */
    }
}
