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
    func fusumaCameraRollUnauthorized()
    
    optional func fusumaClosed()
    optional func fusumaDismissedWithImage(image: UIImage)
}

public var fusumaBaseTintColor       = UIColor.hex("#FFFFFF", alpha: 1.0)
public var fusumaTintColor       = UIColor.hex("#009688", alpha: 1.0)
public var fusumaBackgroundColor = UIColor.hex("#212121", alpha: 1.0)

public var fusumaAlbumImage : UIImage? = nil
public var fusumaCameraImage : UIImage? = nil
public var fusumaCheckImage : UIImage? = nil
public var fusumaCloseImage : UIImage? = nil
public var fusumaFlashOnImage : UIImage? = nil
public var fusumaFlashOffImage : UIImage? = nil
public var fusumaFlipImage : UIImage? = nil
public var fusumaShotImage : UIImage? = nil

public var fusumaCameraRollTitle = "CAMERA ROLL"
public var fusumaCameraTitle = "PHOTO"

public var fusumaTintIcons : Bool = true

public enum FusumaMode {
    case Camera
    case Library
}

public enum FusumaModeOrder {
    case CameraFirst
    case LibraryFirst
}

@objc public class FusumaViewController: UIViewController, FSCameraViewDelegate, FSAlbumViewDelegate {

    private var mode: FusumaMode?
    public var defaultMode: FusumaMode?
    public var modeOrder: FusumaModeOrder = .LibraryFirst
    public var willFilter = true

    @IBOutlet weak var photoLibraryViewerContainer: UIView!
    @IBOutlet weak var cameraShotContainer: UIView!

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var libraryButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!

    @IBOutlet var libraryFirstConstraints: [NSLayoutConstraint]!
    @IBOutlet var cameraFirstConstraints: [NSLayoutConstraint]!
    
    var albumView  = FSAlbumView.instance()
    var cameraView = FSCameraView.instance()
    
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
        
        // Get the custom button images if they're set
        let albumImage = fusumaAlbumImage != nil ? fusumaAlbumImage : UIImage(named: "ic_insert_photo", inBundle: bundle, compatibleWithTraitCollection: nil)
        let cameraImage = fusumaCameraImage != nil ? fusumaCameraImage : UIImage(named: "ic_photo_camera", inBundle: bundle, compatibleWithTraitCollection: nil)
        let checkImage = fusumaCheckImage != nil ? fusumaCheckImage : UIImage(named: "ic_check", inBundle: bundle, compatibleWithTraitCollection: nil)
        let closeImage = fusumaCloseImage != nil ? fusumaCloseImage : UIImage(named: "ic_close", inBundle: bundle, compatibleWithTraitCollection: nil)
        
        if(fusumaTintIcons) {
            libraryButton.setImage(albumImage?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
            libraryButton.setImage(albumImage?.imageWithRenderingMode(.AlwaysTemplate), forState: .Highlighted)
            libraryButton.setImage(albumImage?.imageWithRenderingMode(.AlwaysTemplate), forState: .Selected)
            libraryButton.tintColor = fusumaTintColor
            
            cameraButton.setImage(cameraImage?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
            cameraButton.setImage(cameraImage?.imageWithRenderingMode(.AlwaysTemplate), forState: .Highlighted)
            cameraButton.setImage(cameraImage?.imageWithRenderingMode(.AlwaysTemplate), forState: .Selected)
            cameraButton.tintColor  = fusumaTintColor
            
            closeButton.setImage(closeImage?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
            closeButton.setImage(closeImage?.imageWithRenderingMode(.AlwaysTemplate), forState: .Highlighted)
            closeButton.setImage(closeImage?.imageWithRenderingMode(.AlwaysTemplate), forState: .Selected)
            closeButton.tintColor = fusumaBaseTintColor
            
            doneButton.setImage(checkImage?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
            doneButton.tintColor = fusumaBaseTintColor
            
            cameraButton.adjustsImageWhenHighlighted  = false
            libraryButton.adjustsImageWhenHighlighted = false
        } else {
            libraryButton.setImage(albumImage, forState: .Normal)
            libraryButton.setImage(albumImage, forState: .Highlighted)
            libraryButton.setImage(albumImage, forState: .Selected)
            libraryButton.tintColor = nil
            
            cameraButton.setImage(cameraImage, forState: .Normal)
            cameraButton.setImage(cameraImage, forState: .Highlighted)
            cameraButton.setImage(cameraImage, forState: .Selected)
            cameraButton.tintColor = nil
            
            closeButton.setImage(closeImage, forState: .Normal)
            doneButton.setImage(checkImage, forState: .Normal)
        }
        
        cameraButton.clipsToBounds  = true
        libraryButton.clipsToBounds = true

        changeMode(defaultMode ?? FusumaMode.Library)
        photoLibraryViewerContainer.addSubview(albumView)
        cameraShotContainer.addSubview(cameraView)
        
		titleLabel.textColor = fusumaBaseTintColor
		
        if modeOrder != .LibraryFirst {
            libraryFirstConstraints.forEach { $0.priority = 250 }
            cameraFirstConstraints.forEach { $0.priority = 1000 }
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
        
        changeMode(FusumaMode.Library)
    }
    
    @IBAction func photoButtonPressed(sender: UIButton) {
    
        changeMode(FusumaMode.Camera)
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
    
    func changeMode(mode: FusumaMode) {

        if self.mode == mode {
            
            return
        }
        
        self.mode = mode
        
        dishighlightButtons()
        
        if mode == FusumaMode.Library {
			titleLabel.text = NSLocalizedString(fusumaCameraRollTitle, comment: fusumaCameraRollTitle)
            doneButton.hidden = false
            
            highlightButton(libraryButton)
            self.view.insertSubview(photoLibraryViewerContainer, aboveSubview: cameraShotContainer)
            
        } else {

			titleLabel.text = NSLocalizedString(fusumaCameraTitle, comment: fusumaCameraTitle)
            doneButton.hidden = true
            
            highlightButton(cameraButton)
            self.view.insertSubview(cameraShotContainer, aboveSubview: photoLibraryViewerContainer)
        }
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
        
    }
    
    func highlightButton(button: UIButton) {
        
        button.tintColor = fusumaTintColor
        
        button.addBottomBorder(fusumaTintColor, width: 3)
    }
}
