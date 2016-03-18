//
//  FusumaViewController.swift
//  Fusuma
//
//  Created by Yuta Akizuki on 2015/11/14.
//  Copyright © 2015年 ytakzk. All rights reserved.
//

import UIKit

@objc public protocol FusumaDelegate: class {
    
    func fusumaImageSelected(image: UIImage)
    optional func fusumaDismissedWithImage(image: UIImage)
    func fusumaCameraRollUnauthorized()
}

public var fusumaTintColor       = UIColor.hex("#009688", alpha: 1.0)
public var fusumaBackgroundColor = UIColor.hex("#212121", alpha: 1.0)

public final class FusumaViewController: UIViewController, FSCameraViewDelegate, FSAlbumViewDelegate {
    
    enum Mode {
        case Camera
        case Library
        case Video
    }
    
    var mode: Mode?
    var willFilter = true

    @IBOutlet weak var photoLibraryViewerContainer: UIView!
    @IBOutlet weak var cameraShotContainer: UIView!
    @IBOutlet weak var videoShotContainer: UIView!

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var libraryButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var videoButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    
    var albumView  = FSAlbumView.instance()
    var cameraView = FSCameraView.instance()
    var videoView = FSVideoCameraView.instance()
    
    public weak var delegate: FusumaDelegate? = nil
    
    override public func loadView() {
        
        if let view = UINib(nibName: "FusumaViewController", bundle: NSBundle(forClass: self.classForCoder)).instantiateWithOwner(self, options: nil).first as? UIView {
            
            self.view = view
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
    
        self.view.backgroundColor = fusumaBackgroundColor
        
        cameraView.delegate = self
        albumView.delegate  = self

        menuView.backgroundColor = fusumaBackgroundColor
        menuView.addBottomBorder(UIColor.blackColor(), width: 1.0)
        
        let bundle = NSBundle(forClass: self.classForCoder)
        
        let albumImage = UIImage(named: "ic_insert_photo", inBundle: bundle, compatibleWithTraitCollection: nil)
        let cameraImage = UIImage(named: "ic_photo_camera", inBundle: bundle, compatibleWithTraitCollection: nil)
        let videoImage = UIImage(named: "ic_videocam", inBundle: bundle, compatibleWithTraitCollection: nil)
        let checkImage = UIImage(named: "ic_check", inBundle: bundle, compatibleWithTraitCollection: nil)

        
        libraryButton.setImage(albumImage, forState: .Normal)
        libraryButton.setImage(albumImage, forState: .Highlighted)
        libraryButton.setImage(albumImage, forState: .Selected)

        cameraButton.setImage(cameraImage, forState: .Normal)
        cameraButton.setImage(cameraImage, forState: .Highlighted)
        cameraButton.setImage(cameraImage, forState: .Selected)
        
        videoButton.setImage(videoImage, forState: .Normal)
        videoButton.setImage(videoImage, forState: .Highlighted)
        videoButton.setImage(videoImage, forState: .Selected)
        
        closeButton.tintColor = UIColor.whiteColor()
        
        libraryButton.tintColor = fusumaTintColor
        cameraButton.tintColor  = fusumaTintColor
        videoButton.tintColor  = fusumaTintColor
        
        cameraButton.adjustsImageWhenHighlighted  = false
        libraryButton.adjustsImageWhenHighlighted = false
        videoButton.adjustsImageWhenHighlighted = false
        cameraButton.clipsToBounds  = true
        libraryButton.clipsToBounds = true
        videoButton.clipsToBounds = true

        changeMode(Mode.Library)
        
        photoLibraryViewerContainer.addSubview(albumView)
        cameraShotContainer.addSubview(cameraView)
        videoShotContainer.addSubview(videoView)
        
        doneButton.setImage(checkImage, forState: .Normal)
        doneButton.tintColor = UIColor.whiteColor()        
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }

    override public func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        albumView.frame  = CGRect(origin: CGPointZero, size: photoLibraryViewerContainer.frame.size)
        albumView.layoutIfNeeded()
        cameraView.frame = CGRect(origin: CGPointZero, size: cameraShotContainer.frame.size)
        cameraView.layoutIfNeeded()
        videoView.frame = CGRect(origin: CGPointZero, size: videoShotContainer.frame.size)
        videoView.layoutIfNeeded()
        
        albumView.initialize()
        cameraView.initialize()
        videoView.initialize()
    }

    override public func prefersStatusBarHidden() -> Bool {
        
        return true
    }
    
    @IBAction func closeButtonPressed(sender: UIButton) {

        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func libraryButtonPressed(sender: UIButton) {
        
        changeMode(Mode.Library)
    }
    
    @IBAction func photoButtonPressed(sender: UIButton) {
    
        changeMode(Mode.Camera)
    }
    
    @IBAction func videoButtonPressed(sender: UIButton) {
        
        changeMode(Mode.Video)
    }
    
    @IBAction func doneButtonPressed(sender: UIButton) {
        
        let view = albumView.imageCropView
        
        UIGraphicsBeginImageContextWithOptions(view.frame.size, true, 0)
        let context = UIGraphicsGetCurrentContext()
        CGContextTranslateCTM(context, -albumView.imageCropView.contentOffset.x, -albumView.imageCropView.contentOffset.y)
        view.layer.renderInContext(context!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        delegate?.fusumaImageSelected(image)
        
        self.dismissViewControllerAnimated(true, completion: {
            
            self.delegate?.fusumaDismissedWithImage?(image)
        })
    }
    
    // MARK: FSCameraViewDelegate
    func cameraShotFinished(image: UIImage) {
        
        delegate?.fusumaImageSelected(image)
        self.dismissViewControllerAnimated(true, completion: {
        
            self.delegate?.fusumaDismissedWithImage?(image)
        })
    }
    
    // MARK: FSAlbumViewDelegate
    public func albumViewCameraRollUnauthorized() {
        
        delegate?.fusumaCameraRollUnauthorized()
    }
}

private extension FusumaViewController {
    
    func changeMode(mode: Mode) {

        if self.mode == mode {
            return
        }
        
        self.mode = mode
        
        dishighlightButtons()
        
        switch mode {
        case .Library:
            titleLabel.text = "CAMERA ROLL"
            doneButton.hidden = false
            
            highlightButton(libraryButton)
            self.view.bringSubviewToFront(photoLibraryViewerContainer)
        case .Camera:
            titleLabel.text = "PHOTO"
            doneButton.hidden = true
            
            highlightButton(cameraButton)
            self.view.bringSubviewToFront(cameraShotContainer)
        case .Video:
            titleLabel.text = "VIDEO"
            doneButton.hidden = true
            
            highlightButton(videoButton)
            self.view.bringSubviewToFront(videoShotContainer)
        }
        self.view.bringSubviewToFront(menuView)
    }
    
    
    func dishighlightButtons() {
        
        cameraButton.tintColor  = UIColor.whiteColor()
        libraryButton.tintColor = UIColor.whiteColor()
        videoButton.tintColor = UIColor.whiteColor()
        
        if cameraButton.layer.sublayers?.count > 1 {
            
            for layer in cameraButton.layer.sublayers! {
                
                if let borderColor = layer.borderColor where UIColor(CGColor: borderColor) == fusumaTintColor {
                    
                    layer.removeFromSuperlayer()
                }
                
            }
        }
        
        if libraryButton.layer.sublayers?.count > 1 {
            
            for layer in libraryButton.layer.sublayers! {
                
                if let borderColor = layer.borderColor where UIColor(CGColor: borderColor) == fusumaTintColor {
                    
                    layer.removeFromSuperlayer()
                }
                
            }
        }
        
        if videoButton.layer.sublayers?.count > 1 {
            
            for layer in videoButton.layer.sublayers! {
                
                if let borderColor = layer.borderColor where UIColor(CGColor: borderColor) == fusumaTintColor {
                    
                    layer.removeFromSuperlayer()
                }
                
            }
        }
        
    }
    
    func highlightButton(button: UIButton) {
        
        button.tintColor = fusumaTintColor
        
        button.addBottomBorder(fusumaTintColor, width: 3)
    }
}