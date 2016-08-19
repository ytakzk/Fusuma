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
    func fusuma(fusuma: FusumaViewController, imageSelected image: UIImage, viaMode mode: Int)
    func fusuma(fusuma: FusumaViewController, videoCompletedWithFileURL fileURL: NSURL)
    func fusumaCameraRollUnauthorized(fusuma: FusumaViewController)

  optional func fusumaClosed(fusuma: FusumaViewController)
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

public enum FusumaMode : Int {
  case Camera
  case Library
  case Video
}

public final class FusumaViewController: UIViewController {

    // Mirror module properties to instance variables
    public var hasVideo = false
    public var baseTintColor = fusumaBaseTintColor
    public var tintColor = fusumaTintColor
    public var backgroundColor = fusumaBackgroundColor

    public var albumImage = fusumaAlbumImage
    public var cameraImage = fusumaCameraImage
    public var videoImage = fusumaVideoImage
    public var checkImage = fusumaCheckImage
    public var closeImage = fusumaCloseImage
    public var flashOnImage = fusumaFlashOnImage
    public var flashOffImage = fusumaFlashOffImage
    public var flipImage = fusumaFlipImage
    public var shotImage = fusumaShotImage

    public var videoStartImage = fusumaVideoStartImage
    public var videoStopImage = fusumaVideoStopImage

    public var cropImage = fusumaCropImage

    public var cameraRollTitle = fusumaCameraRollTitle
    public var cameraTitle = fusumaCameraTitle
    public var videoTitle = fusumaVideoTitle

    public var tintIcons = fusumaTintIcons
    // End mirroring properties

    var mode: FusumaMode = .Camera
    public var modeOrder: FusumaModeOrder = .CameraFirst
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

        // @TODO(shrugs) setters for properties set in viewdidLoad
        self.view.backgroundColor = self.backgroundColor
        
        cameraView.delegate = self
        albumView.delegate  = self
        videoView.delegate = self

        menuView.backgroundColor = self.backgroundColor
        menuView.addBottomBorder(UIColor.blackColor(), width: 1.0)
        
        // Get the custom button images if they're set
        let albumImage = self.albumImage ?? self.loadImage(named: "ic_insert_photo")
        let cameraImage = self.cameraImage ?? self.loadImage(named: "ic_photo_camera")
        let videoImage = self.videoImage ?? self.loadImage(named: "ic_videocam")
        let checkImage = self.checkImage ?? self.loadImage(named: "ic_check")
        let closeImage = self.closeImage ?? self.loadImage(named: "ic_close")
        
        if self.tintIcons {
            let templatedAlbumImage = albumImage?.imageWithRenderingMode(.AlwaysTemplate)
            libraryButton.setImage(templatedAlbumImage, forState: .Normal)
            libraryButton.setImage(templatedAlbumImage, forState: .Highlighted)
            libraryButton.setImage(templatedAlbumImage, forState: .Selected)
            libraryButton.tintColor = self.tintColor
            libraryButton.adjustsImageWhenHighlighted = false

            let templatedCameraButton = cameraImage?.imageWithRenderingMode(.AlwaysTemplate)
            cameraButton.setImage(templatedCameraButton, forState: .Normal)
            cameraButton.setImage(templatedCameraButton, forState: .Highlighted)
            cameraButton.setImage(templatedCameraButton, forState: .Selected)
            cameraButton.tintColor = self.tintColor
            cameraButton.adjustsImageWhenHighlighted  = false

            let templatedCloseButton = closeImage?.imageWithRenderingMode(.AlwaysTemplate)
            closeButton.setImage(templatedCloseButton, forState: .Normal)
            closeButton.setImage(templatedCloseButton, forState: .Highlighted)
            closeButton.setImage(templatedCloseButton, forState: .Selected)
            closeButton.tintColor = self.baseTintColor
            closeButton.adjustsImageWhenHighlighted  = false
            
            videoButton.setImage(videoImage, forState: .Normal)
            videoButton.setImage(videoImage, forState: .Highlighted)
            videoButton.setImage(videoImage, forState: .Selected)
            videoButton.tintColor = self.tintColor
            videoButton.adjustsImageWhenHighlighted = false

            let templatedCheckImage = checkImage?.imageWithRenderingMode(.AlwaysTemplate)
            doneButton.setImage(templatedCheckImage, forState: .Normal)
            doneButton.setImage(templatedCheckImage, forState: .Highlighted)
            doneButton.setImage(templatedCheckImage, forState: .Selected)
            doneButton.tintColor = self.baseTintColor
            
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

        changeMode(.Library)
        
        photoLibraryViewerContainer.addSubview(albumView)
        cameraShotContainer.addSubview(cameraView)
        videoShotContainer.addSubview(videoView)
        
        titleLabel.textColor = self.baseTintColor
		
//        if modeOrder != .LibraryFirst {
//            libraryFirstConstraints.forEach { $0.priority = 250 }
//            cameraFirstConstraints.forEach { $0.priority = 1000 }
//        }
        
        if !self.hasVideo {
            
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

    override public func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        albumView.frame  = CGRect(origin: CGPointZero, size: photoLibraryViewerContainer.frame.size)
        albumView.layoutIfNeeded()
        albumView.initialize()

        cameraView.frame = CGRect(origin: CGPointZero, size: cameraShotContainer.frame.size)
        cameraView.layoutIfNeeded()
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
        self.delegate?.fusumaClosed?(self)
    }
    
    @IBAction func libraryButtonPressed(sender: UIButton) {
        changeMode(.Library)
    }
    
    @IBAction func photoButtonPressed(sender: UIButton) {
        changeMode(.Camera)
    }
    
    @IBAction func videoButtonPressed(sender: UIButton) {
        changeMode(.Video)
    }
    
    @IBAction func doneButtonPressed(sender: UIButton) {
        let view = albumView.imageCropView

        if self.cropImage {
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
                        self.delegate?.fusuma(self, imageSelected: result!, viaMode: self.mode.rawValue)
                    })
                }
            })
        } else {
            delegate?.fusuma(self, imageSelected: view.image, viaMode: self.mode.rawValue)
        }
    }
    
}

extension FusumaViewController: FSAlbumViewDelegate, FSCameraViewDelegate, FSVideoCameraViewDelegate {
    
    // MARK: FSCameraViewDelegate
    func cameraShotFinished(image: UIImage) {
        delegate?.fusuma(self, imageSelected: image, viaMode: self.mode.rawValue)
    }
    
    // MARK: FSAlbumViewDelegate
    public func albumViewCameraRollUnauthorized() {
        delegate?.fusumaCameraRollUnauthorized(self)
    }
    
    func videoFinished(withFileURL fileURL: NSURL) {
        delegate?.fusuma(self, videoCompletedWithFileURL: fileURL)
    }
    
}

private extension FusumaViewController {

    func loadImage(named name : String) -> UIImage? {
      let bundle = NSBundle(forClass: self.classForCoder)
      return UIImage(
        named: name,
        inBundle: bundle,
        compatibleWithTraitCollection: nil
      )
    }

    func stopAll() {
        
        if hasVideo {
            self.videoView.stopCamera()
        }
        
        self.cameraView.stopCamera()
    }
    
    func changeMode(mode: FusumaMode) {

        if self.mode == mode {
            return
        }
        
        // operate this switch before changing mode to stop cameras
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
            titleLabel.text = NSLocalizedString(self.cameraRollTitle, comment: self.cameraRollTitle)
            doneButton.hidden = false
            
            highlightButton(libraryButton)
            self.view.bringSubviewToFront(photoLibraryViewerContainer)
        case .Camera:
            titleLabel.text = NSLocalizedString(self.cameraTitle, comment: self.cameraTitle)
            doneButton.hidden = true
            
            highlightButton(cameraButton)
            self.view.bringSubviewToFront(cameraShotContainer)
            cameraView.startCamera()
        case .Video:
            titleLabel.text = self.videoTitle
            doneButton.hidden = true
            
            highlightButton(videoButton)
            self.view.bringSubviewToFront(videoShotContainer)
            videoView.startCamera()
        }
        doneButton.hidden = !hasGalleryPermission
        self.view.bringSubviewToFront(menuView)
    }
    
    
    func dishighlightButtons() {
        cameraButton.tintColor  = self.baseTintColor
        libraryButton.tintColor = self.baseTintColor
        
        if cameraButton.layer.sublayers?.count > 1 {
            
            for layer in cameraButton.layer.sublayers! {
                
                if let borderColor = layer.borderColor where UIColor(CGColor: borderColor) == self.tintColor {
                    
                    layer.removeFromSuperlayer()
                }
                
            }
        }
        
        if libraryButton.layer.sublayers?.count > 1 {
            
            for layer in libraryButton.layer.sublayers! {
                
                if let borderColor = layer.borderColor where UIColor(CGColor: borderColor) == self.tintColor {
                    
                    layer.removeFromSuperlayer()
                }
                
            }
        }
        
        if let videoButton = videoButton {
            
            videoButton.tintColor = self.baseTintColor
            
            if videoButton.layer.sublayers?.count > 1 {
                
                for layer in videoButton.layer.sublayers! {
                    
                    if let borderColor = layer.borderColor where UIColor(CGColor: borderColor) == self.tintColor {
                        
                        layer.removeFromSuperlayer()
                    }
                    
                }
            }
        }
        
    }
    
    func highlightButton(button: UIButton) {
        button.tintColor = self.tintColor
        
        button.addBottomBorder(self.tintColor, width: 3)
    }
}
