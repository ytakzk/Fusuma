//
//  FSVideoCameraView.swift
//  Fusuma
//
//  Created by Brendan Kirchner on 3/18/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import AVFoundation

protocol FSVideoCameraViewDelegate: class {
    func videoFinished(image: UIImage)
}

final class FSVideoCameraView: UIView {

    @IBOutlet weak var previewViewContainer: UIView!
    @IBOutlet weak var shotButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var flipButton: UIButton!
    
    weak var delegate: FSVideoCameraViewDelegate? = nil
    
    var session: AVCaptureSession?
    var device: AVCaptureDevice?
    var videoInput: AVCaptureDeviceInput?
    var videoOutput: AVCaptureVideoDataOutput?
    var focusView: UIView?
    
    static func instance() -> FSVideoCameraView {
        
        return UINib(nibName: "FSVideoCameraView", bundle: NSBundle(forClass: self.classForCoder())).instantiateWithOwner(self, options: nil)[0] as! FSVideoCameraView
    }
    
    func initialize() {
        
        if session != nil {
            
            return
        }
        
        self.backgroundColor = fusumaBackgroundColor
        
        self.hidden = false
        
        // AVCapture
        session = AVCaptureSession()
        
        for device in AVCaptureDevice.devices() {
            
            if let device = device as? AVCaptureDevice where device.position == AVCaptureDevicePosition.Back {
                
                self.device = device
            }
        }
        
        do {
            
            if let session = session {
                
                videoInput = try AVCaptureDeviceInput(device: device)
                
                session.addInput(videoInput)
                
                videoOutput = AVCaptureVideoDataOutput()
                
                session.addOutput(videoOutput)
                
                let videoLayer = AVCaptureVideoPreviewLayer(session: session)
                videoLayer.frame = self.previewViewContainer.bounds
                videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                
                self.previewViewContainer.layer.addSublayer(videoLayer)
                
                session.startRunning()
                
            }
            
            // Focus View
            self.focusView         = UIView(frame: CGRect(x: 0, y: 0, width: 90, height: 90))
            let tapRecognizer      = UITapGestureRecognizer(target: self, action: Selector("focus:"))
            self.previewViewContainer.addGestureRecognizer(tapRecognizer)
            
        } catch {
            
            
        }
        
        flashButton.tintColor = UIColor.whiteColor()
        flipButton.tintColor  = UIColor.whiteColor()
        shotButton.tintColor  = UIColor.whiteColor()
        
        let bundle = NSBundle(forClass: self.classForCoder)
        
        let flashImage = UIImage(named: "ic_flash_off", inBundle: bundle, compatibleWithTraitCollection: nil)
        let flipImage = UIImage(named: "ic_loop", inBundle: bundle, compatibleWithTraitCollection: nil)
        let shotImage = UIImage(named: "ic_radio_button_checked", inBundle: bundle, compatibleWithTraitCollection: nil)
        
        flashButton.setImage(flashImage, forState: .Normal)
        flipButton.setImage(flipImage, forState: .Normal)
        shotButton.setImage(shotImage, forState: .Normal)
        
        flashConfiguration()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "willEnterForegroundNotification:", name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    deinit {
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func willEnterForegroundNotification(notification: NSNotification) {
        
        let status = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        
        if status == AVAuthorizationStatus.Authorized {
            
            session?.startRunning()
            
        } else if status == AVAuthorizationStatus.Denied || status == AVAuthorizationStatus.Restricted {
            
            session?.stopRunning()
        }
    }
    
    @IBAction func shotButtonPressed(sender: UIButton) {
        
        guard let videoOutput = videoOutput else {
            
            return
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            
            let videoConnection = videoOutput.connectionWithMediaType(AVMediaTypeVideo)
            
//            videoOutput.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: { (buffer, error) -> Void in
//                
//                self.session?.stopRunning()
//                
//                let data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
//                
//                if let image = UIImage(data: data), let delegate = self.delegate {
//                    
//                    // Image size
//                    let iw = image.size.width
//                    let ih = image.size.height
//                    
//                    // Frame size
//                    let sw = self.previewViewContainer.frame.width
//                    
//                    // The center coordinate along Y axis
//                    let rcy = ih*0.5
//                    
//                    let imageRef = CGImageCreateWithImageInRect(image.CGImage, CGRect(x: rcy-iw*0.5, y: 0 , width: iw, height: iw))
//                    
//                    let resizedImage = UIImage(CGImage: imageRef!, scale: sw/iw, orientation: image.imageOrientation)
//                    
//                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                        
//                        delegate.cameraShotFinished(resizedImage)
//                        
//                        self.session     = nil
//                        self.device      = nil
//                        self.imageOutput = nil
//                        
//                    })
//                }
//                
//            })
            
        })
    }
    
    @IBAction func flipButtonPressed(sender: UIButton) {
        
        session?.stopRunning()
        
        do {
            
            session?.beginConfiguration()
            
            if let session = session {
                
                for input in session.inputs {
                    
                    session.removeInput(input as! AVCaptureInput)
                }
                
                let position = (videoInput?.device.position == AVCaptureDevicePosition.Front) ? AVCaptureDevicePosition.Back : AVCaptureDevicePosition.Front
                
                for device in AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) {
                    
                    if let device = device as? AVCaptureDevice where device.position == position {
                        
                        videoInput = try AVCaptureDeviceInput(device: device)
                        session.addInput(videoInput)
                        
                    }
                }
                
            }
            
            session?.commitConfiguration()
            
            
        } catch {
            
        }
        
        session?.startRunning()
    }
    
    @IBAction func flashButtonPressed(sender: UIButton) {
        
        do {
            
            if let device = device {
                
                try device.lockForConfiguration()
                
                let mode = device.flashMode
                
                if mode == AVCaptureFlashMode.Off {
                    
                    device.flashMode = AVCaptureFlashMode.On
                    flashButton.setImage(UIImage(named: "ic_flash_on", inBundle: NSBundle(forClass: self.classForCoder), compatibleWithTraitCollection: nil), forState: .Normal)
                    
                } else if mode == AVCaptureFlashMode.On {
                    
                    device.flashMode = AVCaptureFlashMode.Off
                    flashButton.setImage(UIImage(named: "ic_flash_off", inBundle: NSBundle(forClass: self.classForCoder), compatibleWithTraitCollection: nil), forState: .Normal)
                }
                
                device.unlockForConfiguration()
                
            }
            
        } catch _ {
            
            flashButton.setImage(UIImage(named: "ic_flash_off", inBundle: NSBundle(forClass: self.classForCoder), compatibleWithTraitCollection: nil), forState: .Normal)
            return
        }
        
    }

}

extension FSVideoCameraView {
    
    func focus(recognizer: UITapGestureRecognizer) {
        
        let point = recognizer.locationInView(self)
        let viewsize = self.bounds.size
        let newPoint = CGPoint(x: point.y/viewsize.height, y: 1.0-point.x/viewsize.width)
        
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        do {
            
            try device.lockForConfiguration()
            
        } catch _ {
            
            return
        }
        
        if device.isFocusModeSupported(AVCaptureFocusMode.AutoFocus) == true {
            
            device.focusMode = AVCaptureFocusMode.AutoFocus
            device.focusPointOfInterest = newPoint
        }
        
        if device.isExposureModeSupported(AVCaptureExposureMode.ContinuousAutoExposure) == true {
            
            device.exposureMode = AVCaptureExposureMode.ContinuousAutoExposure
            device.exposurePointOfInterest = newPoint
        }
        
        device.unlockForConfiguration()
        
        self.focusView?.alpha = 0.0
        self.focusView?.center = point
        self.focusView?.backgroundColor = UIColor.clearColor()
        self.focusView?.layer.borderColor = UIColor.whiteColor().CGColor
        self.focusView?.layer.borderWidth = 1.0
        self.focusView!.transform = CGAffineTransformMakeScale(1.0, 1.0)
        self.addSubview(self.focusView!)
        
        UIView.animateWithDuration(0.8, delay: 0.0, usingSpringWithDamping: 0.8,
                                   initialSpringVelocity: 3.0, options: UIViewAnimationOptions.CurveEaseIn, // UIViewAnimationOptions.BeginFromCurrentState
            animations: {
                self.focusView!.alpha = 1.0
                self.focusView!.transform = CGAffineTransformMakeScale(0.7, 0.7)
            }, completion: {(finished) in
                self.focusView!.transform = CGAffineTransformMakeScale(1.0, 1.0)
                self.focusView!.removeFromSuperview()
        })
    }
    
    func flashConfiguration() {
        
        do {
            
            if let device = device {
                
                try device.lockForConfiguration()
                
                device.flashMode = AVCaptureFlashMode.Off
                flashButton.setImage(UIImage(named: "ic_flash_off", inBundle: NSBundle(forClass: self.classForCoder), compatibleWithTraitCollection: nil), forState: .Normal)
                
                device.unlockForConfiguration()
                
            }
            
        } catch _ {
            
            return
        }
    }
}
