//
//  Fusuma.swift
//  Fusuma
//
//  Created by Yuta Akizuki on 2015/11/14.
//  Copyright © 2015年 ytakzk. All rights reserved.
//

import UIKit

public protocol FusumaDelegate: class {
    func fusumaImageSelected(image: UIImage)
    func fusumaCameraRollUnauthorized()

}

public var FSTintColor       = UIColor.hex("#009688", alpha: 1.0)
public var FSBackgroundColor = UIColor.hex("#212121", alpha: 1.0)

public final class Fusuma: UIViewController, FSCameraViewDelegate, FSAlbumViewDelegate {
    
    enum Mode {
        case Camera
        case Library
    }
    
    var mode: Mode?
    var willFilter = true

    @IBOutlet weak var photoLibraryViewerContainer: UIView!
    @IBOutlet weak var cameraShotContainer: UIView!

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var libraryButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    
    var albumView  = FSAlbumView.instance()
    var cameraView = FSCameraView.instance()
    
    public weak var delegate: FusumaDelegate? = nil
    
    override public func viewDidLoad() {
        super.viewDidLoad()
    
        self.view.backgroundColor = FSBackgroundColor
        
        cameraView.delegate = self
        albumView.delegate  = self

        menuView.backgroundColor = FSBackgroundColor
        menuView.addBottomBorder(UIColor.blackColor(), width: 1.0)
        
        libraryButton.setImage(UIImage(named: "ic_insert_photo"), forState: .Normal)
        libraryButton.setImage(UIImage(named: "ic_insert_photo"), forState: .Highlighted)
        libraryButton.setImage(UIImage(named: "ic_insert_photo"), forState: .Selected)

        cameraButton.setImage(UIImage(named: "ic_photo_camera"), forState: .Normal)
        cameraButton.setImage(UIImage(named: "ic_photo_camera"), forState: .Highlighted)
        cameraButton.setImage(UIImage(named: "ic_photo_camera"), forState: .Selected)
        
        closeButton.tintColor = UIColor.whiteColor()
        
        libraryButton.tintColor = FSTintColor
        cameraButton.tintColor  = FSTintColor
        
        cameraButton.adjustsImageWhenHighlighted  = false
        libraryButton.adjustsImageWhenHighlighted = false
        cameraButton.clipsToBounds  = true
        libraryButton.clipsToBounds = true

        changeMode(Mode.Library)
        
        photoLibraryViewerContainer.addSubview(albumView)
        cameraShotContainer.addSubview(cameraView)
        
        doneButton.setImage(UIImage(named: "ic_check"), forState: .Normal)
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
        
        albumView.initialize()
        cameraView.initialize()
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
    
    @IBAction func doneButtonPressed(sender: UIButton) {
        
        let view = albumView.imageCropView
        
        UIGraphicsBeginImageContextWithOptions(view.frame.size, true, 0)
        let context = UIGraphicsGetCurrentContext()
        CGContextTranslateCTM(context, -albumView.imageCropView.contentOffset.x, -albumView.imageCropView.contentOffset.y)
        view.layer.renderInContext(context!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        delegate?.fusumaImageSelected(image)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func changeMode(mode: Mode) {

        if self.mode == mode {
            
            return
        }
        
        self.mode = mode
        
        dishighlightButtons()
        
        if mode == Mode.Library {
            
            titleLabel.text = "CAMERA ROLL"
            doneButton.hidden = false
            
            highlightButton(libraryButton)
            self.view.insertSubview(photoLibraryViewerContainer, aboveSubview: cameraShotContainer)
            
        } else {

            titleLabel.text = "PHOTO"
            doneButton.hidden = true
            
            highlightButton(cameraButton)
            self.view.insertSubview(cameraShotContainer, aboveSubview: photoLibraryViewerContainer)
        }
    }
    
    
    func dishighlightButtons() {
        
        cameraButton.tintColor  = UIColor.whiteColor()
        libraryButton.tintColor = UIColor.whiteColor()
        
        if cameraButton.layer.sublayers?.count > 1 {
            
            for layer in cameraButton.layer.sublayers! {
                
                if let borderColor = layer.borderColor where UIColor(CGColor: borderColor) == FSTintColor {
                    
                    layer.removeFromSuperlayer()
                }
                
            }
        }
        
        if libraryButton.layer.sublayers?.count > 1 {
            
            for layer in libraryButton.layer.sublayers! {
                
                if let borderColor = layer.borderColor where UIColor(CGColor: borderColor) == FSTintColor {
                    
                    layer.removeFromSuperlayer()
                }
                
            }
        }
        
    }
    
    func highlightButton(button: UIButton) {
        
        button.tintColor = FSTintColor
        
        button.addBottomBorder(FSTintColor, width: 3)
    }
    
    // MARK: FSCameraViewDelegate
    func cameraShotFinished(image: UIImage) {
        
        delegate?.fusumaImageSelected(image)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: FSAlbumViewDelegate
    func albumViewCameraRollUnauthorized() {
        
        delegate?.fusumaCameraRollUnauthorized()
    }
}