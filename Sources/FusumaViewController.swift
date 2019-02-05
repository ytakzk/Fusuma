//
//  FusumaViewController.swift
//  Fusuma
//
//  Created by Yuta Akizuki on 2015/11/14.
//  Copyright © 2015年 ytakzk. All rights reserved.
//

import UIKit
import Photos

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}

public protocol FusumaDelegate: class {
    func fusumaImageSelected(_ image: UIImage, source: FusumaMode)
    func fusumaMultipleImageSelected(_ images: [UIImage], source: FusumaMode)
    func fusumaVideoCompleted(withFileURL fileURL: URL)
    func fusumaCameraRollUnauthorized()

    // optional
    func fusumaImageSelected(_ image: UIImage, source: FusumaMode, metaData: ImageMetadata)
    func fusumaMultipleImageSelected(_ images: [UIImage], source: FusumaMode, metaData: [ImageMetadata])
    func fusumaDismissedWithImage(_ image: UIImage, source: FusumaMode)
    func fusumaClosed()
    func fusumaWillClosed()
    func fusumaLimitReached()
}

public extension FusumaDelegate {
    func fusumaImageSelected(_ image: UIImage, source: FusumaMode, metaData: ImageMetadata) {}
    func fusumaMultipleImageSelected(_ images: [UIImage], source: FusumaMode, metaData: [ImageMetadata]) {}
    func fusumaDismissedWithImage(_ image: UIImage, source: FusumaMode) {}
    func fusumaClosed() {}
    func fusumaWillClosed() {}
    func fusumaLimitReached() {}
}

public var fusumaBaseTintColor   = UIColor.hex("#c9c7c8", alpha: 1.0)
public var fusumaTintColor       = UIColor.hex("#424141", alpha: 1.0)
public var fusumaBackgroundColor = UIColor.hex("#FCFCFC", alpha: 1.0)

public var fusumaCheckImage: UIImage?
public var fusumaCloseImage: UIImage?
public var fusumaFlashOnImage: UIImage?
public var fusumaFlashOffImage: UIImage?
public var fusumaFlipImage: UIImage?
public var fusumaShotImage: UIImage?

public var fusumaVideoStartImage: UIImage?
public var fusumaVideoStopImage: UIImage?

public var fusumaCropImage: Bool  = true
public var fusumaSavesImage: Bool = false

public var fusumaCameraRollTitle = "Library"
public var fusumaCameraTitle     = "Photo"
public var fusumaVideoTitle      = "Video"
public var fusumaTitleFont       = UIFont(name: "AvenirNext-DemiBold", size: 15)

public var autoDismiss: Bool = true

@objc public enum FusumaMode: Int {
    case camera
    case library
    case video

    static var all: [FusumaMode] {
        return [.camera, .library, .video]
    }
}

public struct ImageMetadata {
    public let mediaType: PHAssetMediaType
    public let pixelWidth: Int
    public let pixelHeight: Int
    public let creationDate: Date?
    public let modificationDate: Date?
    public let location: CLLocation?
    public let duration: TimeInterval
    public let isFavourite: Bool
    public let isHidden: Bool
    public let asset: PHAsset
}

@objc public class FusumaViewController: UIViewController {

    public var cropHeightRatio: CGFloat = 1
    public var allowMultipleSelection: Bool = false
    public var photoSelectionLimit: Int = 1
    public var autoSelectFirstImage: Bool = false

    private var mode: FusumaMode = .library

    public var availableModes: [FusumaMode] = [.library, .camera]
    public var cameraPosition = AVCaptureDevice.Position.back

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

    lazy var albumView  = FSAlbumView.instance()
    lazy var cameraView = FSCameraView.instance()
    lazy var videoView  = FSVideoCameraView.instance()

    fileprivate var hasGalleryPermission: Bool {
        return PHPhotoLibrary.authorizationStatus() == .authorized
    }

    public weak var delegate: FusumaDelegate? = nil

    override public func loadView() {
        if let view = UINib(nibName: "FusumaViewController", bundle: Bundle(for: self.classForCoder)).instantiate(withOwner: self, options: nil).first as? UIView {

            self.view = view
        }
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = fusumaBackgroundColor

        cameraView.delegate = self
        albumView.delegate  = self
        videoView.delegate  = self

        libraryButton.setTitle(fusumaCameraRollTitle, for: .normal)
        cameraButton.setTitle(fusumaCameraTitle, for: .normal)
        videoButton.setTitle(fusumaVideoTitle, for: .normal)

        menuView.backgroundColor = fusumaBackgroundColor
        menuView.addBottomBorder(UIColor.black, width: 1.0)

        albumView.allowMultipleSelection = allowMultipleSelection
        albumView.photoSelectionLimit = photoSelectionLimit
        albumView.autoSelectFirstImage = autoSelectFirstImage

        libraryButton.tintColor = fusumaTintColor
        cameraButton.tintColor  = fusumaTintColor
        videoButton.tintColor   = fusumaTintColor
        closeButton.tintColor   = fusumaTintColor
        doneButton.tintColor    = fusumaTintColor

        let bundle     = Bundle(for: self.classForCoder)
        let checkImage = fusumaCheckImage != nil ? fusumaCheckImage : UIImage(named: "ic_check", in: bundle, compatibleWith: nil)
        let closeImage = fusumaCloseImage != nil ? fusumaCloseImage : UIImage(named: "ic_close", in: bundle, compatibleWith: nil)

        closeButton.setImage(closeImage?.withRenderingMode(.alwaysTemplate), for: .normal)
        doneButton.setImage(checkImage?.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.setImage(closeImage?.withRenderingMode(.alwaysTemplate), for: .selected)
        doneButton.setImage(checkImage?.withRenderingMode(.alwaysTemplate), for: .selected)
        closeButton.setImage(closeImage?.withRenderingMode(.alwaysTemplate), for: .highlighted)
        doneButton.setImage(checkImage?.withRenderingMode(.alwaysTemplate), for: .highlighted)

        photoLibraryViewerContainer.addSubview(albumView)
        cameraShotContainer.addSubview(cameraView)
        videoShotContainer.addSubview(videoView)

        titleLabel.textColor = fusumaTintColor
        titleLabel.font      = fusumaTitleFont

        if availableModes.count == 0 || availableModes.count >= 4 {
            fatalError("the number of items in the variable of availableModes is incorrect.")
        }

        if NSOrderedSet(array: availableModes).count != availableModes.count {
            fatalError("the variable of availableModes should have unique elements.")
        }

        changeMode(availableModes[0], isForced: true)

        var sortedButtons = [UIButton]()

        for (i, mode) in availableModes.enumerated() {
            let button = getTabButton(mode: mode)

            if i == 0 {
                view.addConstraint(NSLayoutConstraint(
                    item:       button,
                    attribute:  .leading,
                    relatedBy:  .equal,
                    toItem:     self.view,
                    attribute:  .leading,
                    multiplier: 1.0,
                    constant:   0.0
                ))
            } else {
                view.addConstraint(NSLayoutConstraint(
                    item:       button,
                    attribute:  .leading,
                    relatedBy:  .equal,
                    toItem:     sortedButtons[i - 1],
                    attribute:  .trailing,
                    multiplier: 1.0,
                    constant:   0.0
                ))
            }

            if i == sortedButtons.count - 1 {
                view.addConstraint(NSLayoutConstraint(
                    item:       button,
                    attribute:  .trailing,
                    relatedBy:  .equal,
                    toItem:     button,
                    attribute:  .trailing,
                    multiplier: 1.0,
                    constant:   0.0
                ))

            }

            view.addConstraint(NSLayoutConstraint(
                item: button,
                attribute: .width,
                relatedBy: .equal, toItem: nil,
                attribute: .width,
                multiplier: 1.0,
                constant: UIScreen.main.bounds.width / CGFloat(availableModes.count)
            ))

            sortedButtons.append(button)
        }

        for m in FusumaMode.all {
            if !availableModes.contains(m) {
                getTabButton(mode: m).removeFromSuperview()
            }
        }

        if availableModes.count == 1 {
            libraryButton.removeFromSuperview()
            cameraButton.removeFromSuperview()
            videoButton.removeFromSuperview()
        }
        
        if availableModes.contains(.camera) {
            if fusumaCropImage {
                let heightRatio = getCropHeightRatio()
                cameraView.croppedAspectRatioConstraint = NSLayoutConstraint(
                    item: cameraView.previewViewContainer,
                    attribute: NSLayoutConstraint.Attribute.height,
                    relatedBy: NSLayoutConstraint.Relation.equal,
                    toItem: cameraView.previewViewContainer,
                    attribute: NSLayoutConstraint.Attribute.width,
                    multiplier: heightRatio,
                    constant: 0)
                
                cameraView.fullAspectRatioConstraint.isActive     = false
                cameraView.croppedAspectRatioConstraint?.isActive = true
                
            } else {
                cameraView.fullAspectRatioConstraint.isActive     = true
                cameraView.croppedAspectRatioConstraint?.isActive = false
            }
            cameraView.initialCaptureDevicePosition = cameraPosition
        }

        doneButton.isEnabled = false
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if availableModes.contains(.library) {
            albumView.frame = CGRect(origin: CGPoint.zero, size: photoLibraryViewerContainer.frame.size)
            albumView.layoutIfNeeded()
            albumView.initialize()
        }

        if availableModes.contains(.camera) {
            cameraView.frame = CGRect(origin: CGPoint.zero, size: cameraShotContainer.frame.size)
            cameraView.layoutIfNeeded()
            cameraView.initialize()
        }

        if availableModes.contains(.video) {
            videoView.frame = CGRect(origin: CGPoint.zero, size: videoShotContainer.frame.size)
            videoView.layoutIfNeeded()
            videoView.initialize()
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAll()
    }

    override public var shouldAutorotate: Bool {
        return false
    }

    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override public var prefersStatusBarHidden : Bool {
        return true
    }

    @IBAction func closeButtonPressed(_ sender: UIButton) {
        self.delegate?.fusumaWillClosed()

        self.doDismiss {
            self.delegate?.fusumaClosed()
        }
    }

    @IBAction func libraryButtonPressed(_ sender: UIButton) {
        changeMode(FusumaMode.library)
    }

    @IBAction func photoButtonPressed(_ sender: UIButton) {
        changeMode(FusumaMode.camera)
    }

    @IBAction func videoButtonPressed(_ sender: UIButton) {
        changeMode(FusumaMode.video)
    }

    @IBAction func doneButtonPressed(_ sender: UIButton) {
        allowMultipleSelection ? fusumaDidFinishInMultipleMode() : fusumaDidFinishInSingleMode()
    }

    fileprivate func doDismiss(completion: (() -> Void)?) {
        if autoDismiss {
            dismiss(animated: true) {
                completion?()
            }
        } else {
            completion?()
        }
    }

    private func fusumaDidFinishInSingleMode() {
        guard let view = albumView.imageCropView else { return }

        if fusumaCropImage {
            let normalizedX = view.contentOffset.x / view.contentSize.width
            let normalizedY = view.contentOffset.y / view.contentSize.height

            let normalizedWidth  = view.frame.width / view.contentSize.width
            let normalizedHeight = view.frame.height / view.contentSize.height

            let cropRect = CGRect(x: normalizedX, y: normalizedY,
                                  width: normalizedWidth, height: normalizedHeight)

            requestImage(with: self.albumView.phAsset, cropRect: cropRect) { (asset, image) in
                self.delegate?.fusumaImageSelected(image, source: self.mode)
                self.doDismiss {
                    self.delegate?.fusumaDismissedWithImage(image, source: self.mode)
                }

                let metaData = self.getMetaData(asset: asset)

                self.delegate?.fusumaImageSelected(image, source: self.mode, metaData: metaData)
            }
        } else {
            delegate?.fusumaImageSelected(view.image, source: mode)

            doDismiss {
                self.delegate?.fusumaDismissedWithImage(view.image, source: self.mode)
            }
        }
    }

    private func requestImage(with asset: PHAsset, cropRect: CGRect, completion: @escaping (PHAsset, UIImage) -> Void) {
        DispatchQueue.global(qos: .default).async(execute: {
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.normalizedCropRect = cropRect
            options.resizeMode = .exact

            let targetWidth  = floor(CGFloat(asset.pixelWidth) * cropRect.width)
            let targetHeight = floor(CGFloat(asset.pixelHeight) * cropRect.height)
            let dimensionW   = max(min(targetHeight, targetWidth), 1024 * UIScreen.main.scale)
            let dimensionH   = dimensionW * self.getCropHeightRatio()

            let targetSize   = CGSize(width: dimensionW, height: dimensionH)

            PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { result, info in
                guard let result = result else { return }

                DispatchQueue.main.async(execute: {
                    completion(asset, result)
                })
            }
        })
    }

    private func fusumaDidFinishInMultipleMode() {
        guard let view = albumView.imageCropView else { return }

        let normalizedX = view.contentOffset.x / view.contentSize.width
        let normalizedY = view.contentOffset.y / view.contentSize.height
        let normalizedWidth  = view.frame.width / view.contentSize.width
        let normalizedHeight = view.frame.height / view.contentSize.height

        let cropRect = CGRect(x: normalizedX,
                              y: normalizedY,
                              width: normalizedWidth,
                              height: normalizedHeight)

        var images = [UIImage]()
        var metaData = [ImageMetadata]()

        for asset in albumView.selectedAssets {
            requestImage(with: asset, cropRect: cropRect) { asset, result in
                images.append(result)
                metaData.append(self.getMetaData(asset: asset))

                if asset == self.albumView.selectedAssets.last {
                    self.doDismiss {
                        self.delegate?.fusumaMultipleImageSelected(images, source: self.mode, metaData: metaData)
                    }
                }
            }
        }
    }

    private func getMetaData(asset: PHAsset) -> ImageMetadata {
        let data = ImageMetadata(mediaType: asset.mediaType ,
                                 pixelWidth: asset.pixelWidth,
                                 pixelHeight: asset.pixelHeight,
                                 creationDate: asset.creationDate,
                                 modificationDate: asset.modificationDate,
                                 location: asset.location,
                                 duration: asset.duration,
                                 isFavourite: asset.isFavorite,
                                 isHidden: asset.isHidden,
                                 asset: asset)
        return data
    }
}

extension FusumaViewController: FSAlbumViewDelegate, FSCameraViewDelegate, FSVideoCameraViewDelegate {
    public func albumbSelectionLimitReached() {
        delegate?.fusumaLimitReached()
    }

    public func albumShouldEnableDoneButton(isEnabled: Bool) {
        doneButton.isEnabled = isEnabled
    }

    public func getCropHeightRatio() -> CGFloat {
        return cropHeightRatio
    }

    // MARK: FSCameraViewDelegate
    func cameraShotFinished(_ image: UIImage) {
        delegate?.fusumaImageSelected(image, source: mode)
        doDismiss {
            self.delegate?.fusumaDismissedWithImage(image, source: self.mode)
        }
    }

    public func albumViewCameraRollAuthorized() {
        // in the case that we're just coming back from granting photo gallery permissions
        // ensure the done button is visible if it should be
        updateDoneButtonVisibility()
    }

    // MARK: FSAlbumViewDelegate
    public func albumViewCameraRollUnauthorized() {
        updateDoneButtonVisibility()
        delegate?.fusumaCameraRollUnauthorized()
    }

    func videoFinished(withFileURL fileURL: URL) {
        delegate?.fusumaVideoCompleted(withFileURL: fileURL)
        doDismiss(completion: nil)
    }

}

private extension FusumaViewController {
    func stopAll() {
        if availableModes.contains(.video) {
            videoView.stopCamera()
        }

        if availableModes.contains(.camera) {
            cameraView.stopCamera()
        }
    }

    func changeMode(_ mode: FusumaMode, isForced: Bool = false) {

        if !isForced && self.mode == mode { return }

        switch self.mode {
        case .camera:
            cameraView.stopCamera()
        case .video:
            videoView.stopCamera()
        default:
            break
        }

        self.mode = mode

        dishighlightButtons()
        updateDoneButtonVisibility()

        switch mode {
        case .library:
            titleLabel.text = NSLocalizedString(fusumaCameraRollTitle, comment: fusumaCameraRollTitle)
            highlightButton(libraryButton)
            view.bringSubviewToFront(photoLibraryViewerContainer)
        case .camera:
            titleLabel.text = NSLocalizedString(fusumaCameraTitle, comment: fusumaCameraTitle)
            highlightButton(cameraButton)
            view.bringSubviewToFront(cameraShotContainer)
            cameraView.startCamera()
        case .video:
            titleLabel.text = NSLocalizedString(fusumaVideoTitle, comment: fusumaVideoTitle)
            highlightButton(videoButton)
            view.bringSubviewToFront(videoShotContainer)
            videoView.startCamera()
        }

        view.bringSubviewToFront(menuView)
    }

    func updateDoneButtonVisibility() {
        guard hasGalleryPermission else {
            doneButton.isHidden = true
            return
        }

        switch mode {
        case .library:
            doneButton.isHidden = false
        default:
            doneButton.isHidden = true
        }
    }

    func dishighlightButtons() {
        cameraButton.setTitleColor(fusumaBaseTintColor, for: .normal)
        if let libraryButton = libraryButton {
            libraryButton.setTitleColor(fusumaBaseTintColor, for: .normal)
        }

        if let videoButton = videoButton {
            videoButton.setTitleColor(fusumaBaseTintColor, for: .normal)
        }
    }

    func highlightButton(_ button: UIButton) {
        button.setTitleColor(fusumaTintColor, for: .normal)
    }

    func getTabButton(mode: FusumaMode) -> UIButton {
        switch mode {
        case .library:
            return libraryButton
        case .camera:
            return cameraButton
        case .video:
            return videoButton
        }
    }
}
