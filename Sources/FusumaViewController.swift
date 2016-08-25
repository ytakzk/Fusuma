//
//  FusumaViewController.swift
//  Fusuma
//
//  Created by Yuta Akizuki on 2015/11/14.
//  Copyright © 2015年 ytakzk. All rights reserved.
//

import UIKit
import Photos

@objc public protocol FusumaDelegate: class {
    
    func fusumaImageSelected(image: UIImage)
    optional func fusumaDismissedWithImage(image: UIImage)
    func fusumaVideoCompleted(withFileURL fileURL: NSURL)
    func fusumaCameraRollUnauthorized()
    
    optional func fusumaClosed()
}

public var fusumaBaseTintColor   = UIColor.hex("#FFFFFF", alpha: 1.0)
public var fusumaTintColor       = UIColor.hex("#009688", alpha: 1.0)
public var fusumaBackgroundColor = UIColor.hex("#212121", alpha: 1.0)

public var fusumaAlbumImage : UIImage? = nil
public var fusumaCameraImage : UIImage? = nil
public var fusumaVideoImage : UIImage? = nil
public var fusumaCheckImage : UIImage? = nil
public var fusumaCloseImage : UIImage? = nil
public var fusumaFlashOnImage : UIImage? = nil
public var fusumaFlashOffImage : UIImage? = nil
public var fusumaFlipImage : UIImage? = nil
public var fusumaShotImage : UIImage? = nil

public var fusumaVideoStartImage : UIImage? = nil
public var fusumaVideoStopImage : UIImage? = nil

public var fusumaCropImage: Bool = true

public var fusumaCameraRollTitle = "CAMERA ROLL"
public var fusumaCameraTitle = "PHOTO"
public var fusumaVideoTitle = "VIDEO"

public var fusumaTintIcons : Bool = true

public enum FusumaModeOrder {
    case CameraFirst
    case LibraryFirst
}

//@objc public class FusumaViewController: UIViewController, FSCameraViewDelegate, FSAlbumViewDelegate {
public final class FusumaViewController: UIViewController {
    
    enum Mode {
        case Camera
        case Library
        case Video
    }

    public var hasVideo = false

    var mode: Mode = Mode.Camera
    public var modeOrder: FusumaModeOrder = .LibraryFirst
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

    @IBOutlet var libraryFirstConstraints: [NSLayoutConstraint]!
    @IBOutlet var cameraFirstConstraints: [NSLayoutConstraint]!
    
    lazy var albumView  = FSAlbumView.instance()
    lazy var cameraView = FSCameraView.instance()
    lazy var videoView = FSVideoCameraView.instance()

    private var hasGalleryPermission: Bool {
        return PHPhotoLibrary.authorizationStatus() == .Authorized
    }
    
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
        videoView.delegate = self

        menuView.backgroundColor = fusumaBackgroundColor
        menuView.addBottomBorder(UIColor.blackColor(), width: 1.0)
        
        let bundle = NSBundle(forClass: self.classForCoder)
        
        // Get the custom button images if they're set
        let albumImage = fusumaAlbumImage != nil ? fusumaAlbumImage : UIImage(named: "ic_insert_photo", inBundle: bundle, compatibleWithTraitCollection: nil)
        let cameraImage = fusumaCameraImage != nil ? fusumaCameraImage : UIImage(named: "ic_photo_camera", inBundle: bundle, compatibleWithTraitCollection: nil)
        
        let videoImage = fusumaVideoImage != nil ? fusumaVideoImage : UIImage(named: "ic_videocam", inBundle: bundle, compatibleWithTraitCollection: nil)

        
        let checkImage = fusumaCheckImage != nil ? fusumaCheckImage : UIImage(named: "ic_check", inBundle: bundle, compatibleWithTraitCollection: nil)
        let closeImage = fusumaCloseImage != nil ? fusumaCloseImage : UIImage(named: "ic_close", inBundle: bundle, compatibleWithTraitCollection: nil)
        
        if fusumaTintIcons {
            
            libraryButton.setImage(albumImage?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
            libraryButton.setImage(albumImage?.imageWithRenderingMode(.AlwaysTemplate), forState: .Highlighted)
            libraryButton.setImage(albumImage?.imageWithRenderingMode(.AlwaysTemplate), forState: .Selected)
            libraryButton.tintColor = fusumaTintColor
            libraryButton.adjustsImageWhenHighlighted = false

            cameraButton.setImage(cameraImage?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
            cameraButton.setImage(cameraImage?.imageWithRenderingMode(.AlwaysTemplate), forState: .Highlighted)
            cameraButton.setImage(cameraImage?.imageWithRenderingMode(.AlwaysTemplate), forState: .Selected)
            cameraButton.tintColor  = fusumaTintColor
            cameraButton.adjustsImageWhenHighlighted  = false
            
            closeButton.setImage(closeImage?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
            closeButton.setImage(closeImage?.imageWithRenderingMode(.AlwaysTemplate), forState: .Highlighted)
            closeButton.setImage(closeImage?.imageWithRenderingMode(.AlwaysTemplate), forState: .Selected)
            closeButton.tintColor = fusumaBaseTintColor
            
            videoButton.setImage(videoImage, forState: .Normal)
            videoButton.setImage(videoImage, forState: .Highlighted)
            videoButton.setImage(videoImage, forState: .Selected)
            videoButton.tintColor  = fusumaTintColor
            videoButton.adjustsImageWhenHighlighted = false
            
            doneButton.setImage(checkImage?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
            doneButton.tintColor = fusumaBaseTintColor
            
        } else {
            
            libraryButton.setImage(albumImage, forState: .Normal)
            libraryButton.setImage(albumImage, forState: .Highlighted)
            libraryButton.setImage(albumImage, forState: .Selected)
            libraryButton.tintColor = nil
            
            cameraButton.setImage(cameraImage, forState: .Normal)
            cameraButton.setImage(cameraImage, forState: .Highlighted)
            cameraButton.setImage(cameraImage, forState: .Selected)
            cameraButton.tintColor = nil

            videoButton.setImage(videoImage, forState: .Normal)
            videoButton.setImage(videoImage, forState: .Highlighted)
            videoButton.setImage(videoImage, forState: .Selected)
            videoButton.tintColor = nil
            
            closeButton.setImage(closeImage, forState: .Normal)
            doneButton.setImage(checkImage, forState: .Normal)
        }
        
        cameraButton.clipsToBounds  = true
        libraryButton.clipsToBounds = true
        videoButton.clipsToBounds = true

        changeMode(Mode.Library)
        
        photoLibraryViewerContainer.addSubview(albumView)
        cameraShotContainer.addSubview(cameraView)
        videoShotContainer.addSubview(videoView)
        
		titleLabel.textColor = fusumaBaseTintColor
		
//        if modeOrder != .LibraryFirst {
//            libraryFirstConstraints.forEach { $0.priority = 250 }
//            cameraFirstConstraints.forEach { $0.priority = 1000 }
//        }
        
        if !hasVideo {
            
            videoButton.removeFromSuperview()
            
            self.view.addConstraint(NSLayoutConstraint(
                item:       self.view,
                attribute:  .Trailing,
                relatedBy:  .Equal,
                toItem:     cameraButton,
                attribute:  .Trailing,
                multiplier: 1.0,
                constant:   0
                )
            )
            
            self.view.layoutIfNeeded()
        }
        
        if fusumaCropImage {
            cameraView.fullAspectRatioConstraint.active = false
            cameraView.croppedAspectRatioConstraint.active = true
        } else {
            cameraView.fullAspectRatioConstraint.active = true
            cameraView.croppedAspectRatioConstraint.active = false
        }
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

        
        albumView.initialize()
        cameraView.initialize()
        
        if hasVideo {

            videoView.frame = CGRect(origin: CGPointZero, size: videoShotContainer.frame.size)
            videoView.layoutIfNeeded()
            videoView.initialize()
        }
    }
    
    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.stopAll()
    }

    override public func prefersStatusBarHidden() -> Bool {
        
        return true
    }
    
    @IBAction func closeButtonPressed(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: {
            
            self.delegate?.fusumaClosed?()
        })
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

        if fusumaCropImage {
            let normalizedX = view.contentOffset.x / view.contentSize.width
            let normalizedY = view.contentOffset.y / view.contentSize.height
            
            let normalizedWidth = view.frame.width / view.contentSize.width
            let normalizedHeight = view.frame.height / view.contentSize.height
            
            let cropRect = CGRect(x: normalizedX, y: normalizedY, width: normalizedWidth, height: normalizedHeight)
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                
                let options = PHImageRequestOptions()
                options.deliveryMode = .HighQualityFormat
                options.networkAccessAllowed = true
                options.normalizedCropRect = cropRect
                options.resizeMode = .Exact
                
                let targetWidth = floor(CGFloat(self.albumView.phAsset.pixelWidth) * cropRect.width)
                let targetHeight = floor(CGFloat(self.albumView.phAsset.pixelHeight) * cropRect.height)
                let dimension = max(min(targetHeight, targetWidth), 1024 * UIScreen.mainScreen().scale)
                
                let targetSize = CGSize(width: dimension, height: dimension)
                
                PHImageManager.defaultManager().requestImageForAsset(self.albumView.phAsset, targetSize: targetSize,
                contentMode: .AspectFill, options: options) {
                    result, info in
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        self.delegate?.fusumaImageSelected(result!)
                        
                        self.dismissViewControllerAnimated(true, completion: {
                            self.delegate?.fusumaDismissedWithImage?(result!)
                        })
                    })
                }
            })
        } else {
            print("no image crop ")
            delegate?.fusumaImageSelected(view.image)
            
            self.dismissViewControllerAnimated(true, completion: {
                self.delegate?.fusumaDismissedWithImage?(view.image)
            })
        }
    }
    
}

extension FusumaViewController: FSAlbumViewDelegate, FSCameraViewDelegate, FSVideoCameraViewDelegate {
    
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
    
    func videoFinished(withFileURL fileURL: NSURL) {
        delegate?.fusumaVideoCompleted(withFileURL: fileURL)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}

private extension FusumaViewController {
    
    func stopAll() {
        
        if hasVideo {

            self.videoView.stopCamera()
        }
        
        self.cameraView.stopCamera()
    }
    
    func changeMode(mode: Mode) {

        if self.mode == mode {
            return
        }
        
        //operate this switch before changing mode to stop cameras
        switch self.mode {
        case .Library:
            break
        case .Camera:
            self.cameraView.stopCamera()
        case .Video:
            self.videoView.stopCamera()
        }
        
        self.mode = mode
        
        dishighlightButtons()
        
        switch mode {
        case .Library:
            titleLabel.text = NSLocalizedString(fusumaCameraRollTitle, comment: fusumaCameraRollTitle)
            doneButton.hidden = false
            
            highlightButton(libraryButton)
            self.view.bringSubviewToFront(photoLibraryViewerContainer)
        case .Camera:
            titleLabel.text = NSLocalizedString(fusumaCameraTitle, comment: fusumaCameraTitle)
            doneButton.hidden = true
            
            highlightButton(cameraButton)
            self.view.bringSubviewToFront(cameraShotContainer)
            cameraView.startCamera()
        case .Video:
            titleLabel.text = fusumaVideoTitle
            doneButton.hidden = true
            
            highlightButton(videoButton)
            self.view.bringSubviewToFront(videoShotContainer)
            videoView.startCamera()
        }
        doneButton.hidden = !hasGalleryPermission
        self.view.bringSubviewToFront(menuView)
    }
    
    
    func dishighlightButtons() {
        cameraButton.tintColor  = fusumaBaseTintColor
        libraryButton.tintColor = fusumaBaseTintColor
        
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
        
        if let videoButton = videoButton {
            
            videoButton.tintColor = fusumaBaseTintColor
            
            if videoButton.layer.sublayers?.count > 1 {
                
                for layer in videoButton.layer.sublayers! {
                    
                    if let borderColor = layer.borderColor where UIColor(CGColor: borderColor) == fusumaTintColor {
                        
                        layer.removeFromSuperlayer()
                    }
                    
                }
            }
        }
        
    }
    
    func highlightButton(button: UIButton) {
        
        button.tintColor = fusumaTintColor
        
        button.addBottomBorder(fusumaTintColor, width: 3)
    }
}
