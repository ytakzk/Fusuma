//
//  FSCameraView.swift
//  Fusuma
//
//  Created by Yuta Akizuki on 2015/11/14.
//  Copyright © 2015年 ytakzk. All rights reserved.
//

import UIKit
import AVFoundation

@objc protocol FSCameraViewDelegate: class {
    func cameraShotFinished(image: UIImage)
}

final class FSCameraView: UIView, UIGestureRecognizerDelegate {

    @IBOutlet weak var previewViewContainer: UIView!
    @IBOutlet weak var shotButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var flipButton: UIButton!
    @IBOutlet weak var croppedAspectRatioConstraint: NSLayoutConstraint!
    @IBOutlet weak var fullAspectRatioConstraint: NSLayoutConstraint!
    
    weak var delegate: FSCameraViewDelegate? = nil
    
    var session: AVCaptureSession?
    var device: AVCaptureDevice?
    var videoInput: AVCaptureDeviceInput?
    var imageOutput: AVCaptureStillImageOutput?
    var focusView: UIView?

    var flashOffImage: UIImage?
    var flashOnImage: UIImage?
    
    static func instance() -> FSCameraView {
        
        return UINib(nibName: "FSCameraView", bundle: NSBundle(forClass: self.classForCoder())).instantiateWithOwner(self, options: nil)[0] as! FSCameraView
    }
    
    func initialize() {
        
        if session != nil {
            
            return
        }
        
        self.backgroundColor = fusumaBackgroundColor
        
        let bundle = NSBundle(forClass: self.classForCoder)
        
        flashOnImage = fusumaFlashOnImage != nil ? fusumaFlashOnImage : UIImage(named: "ic_flash_on", inBundle: bundle, compatibleWithTraitCollection: nil)
        flashOffImage = fusumaFlashOffImage != nil ? fusumaFlashOffImage : UIImage(named: "ic_flash_off", inBundle: bundle, compatibleWithTraitCollection: nil)
        let flipImage = fusumaFlipImage != nil ? fusumaFlipImage : UIImage(named: "ic_loop", inBundle: bundle, compatibleWithTraitCollection: nil)
        let shotImage = fusumaShotImage != nil ? fusumaShotImage : UIImage(named: "ic_radio_button_checked", inBundle: bundle, compatibleWithTraitCollection: nil)
        
        if(fusumaTintIcons) {
            flashButton.tintColor = fusumaBaseTintColor
            flipButton.tintColor  = fusumaBaseTintColor
            shotButton.tintColor  = fusumaBaseTintColor
            
            flashButton.setImage(flashOffImage?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
            flipButton.setImage(flipImage?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
            shotButton.setImage(shotImage?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        } else {
            flashButton.setImage(flashOffImage, forState: .Normal)
            flipButton.setImage(flipImage, forState: .Normal)
            shotButton.setImage(shotImage, forState: .Normal)
        }

        
        self.hidden = false
        
        // AVCapture
        session = AVCaptureSession()
        
        for device in AVCaptureDevice.devices() {
            
            if let device = device as? AVCaptureDevice where device.position == AVCaptureDevicePosition.Back {
                
                self.device = device
                
                if !device.hasFlash {
                    
                    flashButton.hidden = true
                }
            }
        }
        
        do {

            if let session = session {

                videoInput = try AVCaptureDeviceInput(device: device)

                session.addInput(videoInput)
                
                imageOutput = AVCaptureStillImageOutput()
                
                session.addOutput(imageOutput)
                
                let videoLayer = AVCaptureVideoPreviewLayer(session: session)
                videoLayer.frame = self.previewViewContainer.bounds
                videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                
                self.previewViewContainer.layer.addSublayer(videoLayer)
                
                session.sessionPreset = AVCaptureSessionPresetPhoto

                session.startRunning()
                
            }
            
            // Focus View
            self.focusView         = UIView(frame: CGRect(x: 0, y: 0, width: 90, height: 90))
            let tapRecognizer      = UITapGestureRecognizer(target: self, action:#selector(FSCameraView.focus(_:)))
            tapRecognizer.delegate = self
            self.previewViewContainer.addGestureRecognizer(tapRecognizer)
            
        } catch {
            
        }
        flashConfiguration()
        
        self.startCamera()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(FSCameraView.willEnterForegroundNotification(_:)), name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    func willEnterForegroundNotification(notification: NSNotification) {
        
        let status = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        
        if status == AVAuthorizationStatus.Authorized {
            
            session?.startRunning()
            
        } else if status == AVAuthorizationStatus.Denied || status == AVAuthorizationStatus.Restricted {
            
            session?.stopRunning()
        }
    }
    
    deinit {
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func startCamera() {
        
        let status = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        
        if status == AVAuthorizationStatus.Authorized {

            session?.startRunning()
            
        } else if status == AVAuthorizationStatus.Denied || status == AVAuthorizationStatus.Restricted {

            session?.stopRunning()
        }
    }
    
    func stopCamera() {
        session?.stopRunning()
    }
    
    @IBAction func shotButtonPressed(sender: UIButton) {
        
        guard let imageOutput = imageOutput else {
            
            return
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in

            let videoConnection = imageOutput.connectionWithMediaType(AVMediaTypeVideo)

            let orientation: UIDeviceOrientation = UIDevice.currentDevice().orientation
            switch (orientation) {
            case .Portrait:
                videoConnection.videoOrientation = .Portrait
            case .PortraitUpsideDown:
                videoConnection.videoOrientation = .PortraitUpsideDown
            case .LandscapeRight:
                videoConnection.videoOrientation = .LandscapeLeft
            case .LandscapeLeft:
                videoConnection.videoOrientation = .LandscapeRight
            default:
                videoConnection.videoOrientation = .Portrait
            }

            imageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: { (buffer, error) -> Void in
                
                self.session?.stopRunning()
                
                let data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
                
                if let image = UIImage(data: data), let delegate = self.delegate {
                    
                    // Image size
                    var iw: CGFloat
                    var ih: CGFloat

                    switch (orientation) {
                    case .LandscapeLeft, .LandscapeRight:
                        // Swap width and height if orientation is landscape
                        iw = image.size.height
                        ih = image.size.width
                    default:
                        iw = image.size.width
                        ih = image.size.height
                    }
                    
                    // Frame size
                    let sw = self.previewViewContainer.frame.width
                    
                    // The center coordinate along Y axis
                    let rcy = ih * 0.5

                    let imageRef = CGImageCreateWithImageInRect(image.CGImage, CGRect(x: rcy-iw*0.5, y: 0 , width: iw, height: iw))
                    
                    
                                        
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        if fusumaCropImage {
                            let resizedImage = UIImage(CGImage: imageRef!, scale: sw/iw, orientation: image.imageOrientation)
                            delegate.cameraShotFinished(resizedImage)
                        } else {
                            delegate.cameraShotFinished(image)
                        }
                        
                        self.session     = nil
                        self.device      = nil
                        self.imageOutput = nil
                        
                    })
                }
                
            })
            
        })
    }
    
    @IBAction func flipButtonPressed(sender: UIButton) {

        if !cameraIsAvailable() {

            return
        }
        
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

        if !cameraIsAvailable() {

            return
        }

        do {

            if let device = device {
                
                guard device.hasFlash else { return }
            
                try device.lockForConfiguration()
                
                let mode = device.flashMode
                
                if mode == AVCaptureFlashMode.Off {
                    
                    device.flashMode = AVCaptureFlashMode.On
                    flashButton.setImage(flashOnImage, forState: .Normal)
                    
                } else if mode == AVCaptureFlashMode.On {
                    
                    device.flashMode = AVCaptureFlashMode.Off
                    flashButton.setImage(flashOffImage, forState: .Normal)
                }
                
                device.unlockForConfiguration()

            }

        } catch _ {

            flashButton.setImage(flashOffImage, forState: .Normal)
            return
        }
 
    }
}

extension FSCameraView {
    
    @objc func focus(recognizer: UITapGestureRecognizer) {
        
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
        self.focusView?.layer.borderColor = fusumaBaseTintColor.CGColor
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
                
                guard device.hasFlash else { return }
                
                try device.lockForConfiguration()
                
                device.flashMode = AVCaptureFlashMode.Off
                flashButton.setImage(flashOffImage, forState: .Normal)
                
                device.unlockForConfiguration()
                
            }
            
        } catch _ {
            
            return
        }
    }

    func cameraIsAvailable() -> Bool {

        let status = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)

        if status == AVAuthorizationStatus.Authorized {

            return true
        }

        return false
    }
}
