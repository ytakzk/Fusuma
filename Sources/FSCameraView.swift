//
//  FSCameraView.swift
//  Fusuma
//
//  Created by Yuta Akizuki on 2015/11/14.
//  Copyright © 2015年 ytakzk. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMotion
import Photos

@objc protocol FSCameraViewDelegate: class {
    func cameraShotFinished(_ image: UIImage)
}

final class FSCameraView: UIView, UIGestureRecognizerDelegate {
    @IBOutlet weak var previewViewContainer: UIView!
    @IBOutlet weak var shotButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var flipButton: UIButton!
    @IBOutlet weak var fullAspectRatioConstraint: NSLayoutConstraint!
    var croppedAspectRatioConstraint: NSLayoutConstraint?
    var initialCaptureDevicePosition: AVCaptureDevice.Position = .back

    weak var delegate: FSCameraViewDelegate? = nil

    private var session: AVCaptureSession?
    private var device: AVCaptureDevice?
    private var videoInput: AVCaptureDeviceInput?
    private var imageOutput: AVCaptureStillImageOutput?
    private var videoLayer: AVCaptureVideoPreviewLayer?

    private var focusView: UIView?

    private var flashOffImage: UIImage?
    private var flashOnImage: UIImage?

    private var motionManager: CMMotionManager?
    private var currentDeviceOrientation: UIDeviceOrientation?
    private var zoomFactor: CGFloat = 1.0

    static func instance() -> FSCameraView {
        return UINib(nibName: "FSCameraView", bundle: Bundle(for: self.classForCoder())).instantiate(withOwner: self, options: nil)[0] as! FSCameraView
    }

    func initialize() {
        guard session == nil else { return }

        self.backgroundColor = fusumaBackgroundColor

        let bundle = Bundle(for: self.classForCoder)

        flashOnImage = fusumaFlashOnImage != nil ? fusumaFlashOnImage : UIImage(named: "ic_flash_on", in: bundle, compatibleWith: nil)
        flashOffImage = fusumaFlashOffImage != nil ? fusumaFlashOffImage : UIImage(named: "ic_flash_off", in: bundle, compatibleWith: nil)
        let flipImage = fusumaFlipImage != nil ? fusumaFlipImage : UIImage(named: "ic_loop", in: bundle, compatibleWith: nil)
        let shotImage = fusumaShotImage != nil ? fusumaShotImage : UIImage(named: "ic_shutter", in: bundle, compatibleWith: nil)

        flashButton.tintColor = fusumaBaseTintColor
        flipButton.tintColor  = fusumaBaseTintColor
        shotButton.tintColor  = fusumaBaseTintColor

        flashButton.setImage(flashOffImage?.withRenderingMode(.alwaysTemplate), for: .normal)
        flipButton.setImage(flipImage?.withRenderingMode(.alwaysTemplate), for: .normal)
        shotButton.setImage(shotImage?.withRenderingMode(.alwaysTemplate), for: .normal)

        isHidden = false

        // AVCapture
        session = AVCaptureSession()

        guard let session = session else { return }

        for device in AVCaptureDevice.devices() {
            if device.position == initialCaptureDevicePosition {
                self.device = device

                if !device.hasFlash {
                    flashButton.isHidden = true
                }
            }
        }

        if let device = device, let _videoInput = try? AVCaptureDeviceInput(device: device) {
            videoInput = _videoInput
            session.addInput(videoInput!)

            imageOutput = AVCaptureStillImageOutput()

            session.addOutput(imageOutput!)

            videoLayer = AVCaptureVideoPreviewLayer(session: session)
            videoLayer?.frame = previewViewContainer.bounds
            videoLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill

            previewViewContainer.layer.addSublayer(videoLayer!)

            session.sessionPreset = AVCaptureSession.Preset.photo

            session.startRunning()

            // Focus View
            focusView = UIView(frame: CGRect(x: 0, y: 0, width: 90, height: 90))
            let tapRecognizer = UITapGestureRecognizer(target: self, action:#selector(FSCameraView.focus(_:)))
            tapRecognizer.delegate = self
            previewViewContainer.addGestureRecognizer(tapRecognizer)
        }

        flashConfiguration()
        startCamera()

        NotificationCenter.default.addObserver(self, selector: #selector(FSCameraView.willEnterForegroundNotification(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)

        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchToZoom))
        previewViewContainer.addGestureRecognizer(pinchGestureRecognizer)
    }

    @objc func willEnterForegroundNotification(_ notification: Notification) {
        startCamera()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func startCamera() {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized:
            session?.startRunning()

            motionManager = CMMotionManager()
            motionManager!.accelerometerUpdateInterval = 0.2
            motionManager!.startAccelerometerUpdates(to: OperationQueue()) { [unowned self] (data, _) in
                if let data = data {
                    if abs(data.acceleration.y) < abs(data.acceleration.x) {
                        self.currentDeviceOrientation = data.acceleration.x > 0 ? .landscapeRight : .landscapeLeft
                    } else {
                        self.currentDeviceOrientation = data.acceleration.y > 0 ? .portraitUpsideDown : .portrait
                    }
                }
            }
        case .denied, .restricted:
            stopCamera()
        default:
            break
        }
    }

    func stopCamera() {
        session?.stopRunning()
        motionManager?.stopAccelerometerUpdates()
        currentDeviceOrientation = nil
    }

    @IBAction func shotButtonPressed(_ sender: UIButton) {
        guard let imageOutput = imageOutput else {
            return
        }

        DispatchQueue.global(qos: .default).async(execute: { () -> Void in
            guard let videoConnection = imageOutput.connection(with: AVMediaType.video) else { return }

            imageOutput.captureStillImageAsynchronously(from: videoConnection) { (buffer, error) -> Void in
                self.stopCamera()

                guard let buffer = buffer,
                    let data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer),
                    let image = UIImage(data: data),
                    let cgImage = image.cgImage,
                    let delegate = self.delegate,
                    let videoLayer = self.videoLayer
                else {
                    return
                }

                let rect   = videoLayer.metadataOutputRectConverted(fromLayerRect: videoLayer.bounds)
                let width  = CGFloat(cgImage.width)
                let height = CGFloat(cgImage.height)

                let cropRect = CGRect(x: rect.origin.x * width,
                                      y: rect.origin.y * height,
                                      width: rect.size.width * width,
                                      height: rect.size.height * height)

                guard let img = cgImage.cropping(to: cropRect) else {
                    return
                }

                let croppedUIImage = UIImage(cgImage: img, scale: 1.0, orientation: image.imageOrientation)

                DispatchQueue.main.async(execute: { () -> Void in
                    delegate.cameraShotFinished(croppedUIImage)

                    if fusumaSavesImage {
                        self.saveImageToCameraRoll(image: croppedUIImage)
                    }

                    self.session       = nil
                    self.videoLayer    = nil
                    self.device        = nil
                    self.imageOutput   = nil
                    self.motionManager = nil
                })
            }
        })
    }

    @IBAction func flipButtonPressed(_ sender: UIButton) {
        guard cameraIsAvailable else { return }

        session?.stopRunning()

        do {
            session?.beginConfiguration()

            if let session = session {
                for input in session.inputs {
                    session.removeInput(input)
                }

                let position = (videoInput?.device.position == AVCaptureDevice.Position.front) ? AVCaptureDevice.Position.back : AVCaptureDevice.Position.front

                for device in AVCaptureDevice.devices(for: AVMediaType.video) {
                    if device.position == position {
                        videoInput = try AVCaptureDeviceInput(device: device)
                        session.addInput(videoInput!)
                    }
                }

            }

            session?.commitConfiguration()
        } catch {
        }

        session?.startRunning()
    }

    @IBAction func flashButtonPressed(_ sender: UIButton) {
        if !cameraIsAvailable { return }

        do {
            guard let device = device, device.hasFlash else { return }

            try device.lockForConfiguration()

            switch device.flashMode {
            case .off:
                device.flashMode = AVCaptureDevice.FlashMode.on
                flashButton.setImage(flashOnImage?.withRenderingMode(.alwaysTemplate), for: UIControl.State())
            case .on:
                device.flashMode = AVCaptureDevice.FlashMode.off
                flashButton.setImage(flashOffImage?.withRenderingMode(.alwaysTemplate), for: UIControl.State())
            default:
                break
            }

            device.unlockForConfiguration()
        } catch _ {
            flashButton.setImage(flashOffImage?.withRenderingMode(.alwaysTemplate), for: UIControl.State())

            return
        }
    }

    @objc private func handlePinchToZoom(_ pinch: UIPinchGestureRecognizer) {
        guard let device = device else { return }

        func minMaxZoom(_ factor: CGFloat) -> CGFloat {
            return min(max(factor, 1.0), device.activeFormat.videoMaxZoomFactor)
        }

        func update(scale factor: CGFloat) {
            do {
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }
                device.videoZoomFactor = factor
            } catch {
                debugPrint(error)
            }
        }

        let newScaleFactor = minMaxZoom(pinch.scale * zoomFactor)

        switch pinch.state {
        case .began: fallthrough
        case .changed: update(scale: newScaleFactor)
        case .ended:
            zoomFactor = minMaxZoom(newScaleFactor)
            update(scale: zoomFactor)
        default: break
        }
    }
}

fileprivate extension FSCameraView {
    func saveImageToCameraRoll(image: UIImage) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }, completionHandler: nil)
    }

    @objc func focus(_ recognizer: UITapGestureRecognizer) {
        let point = recognizer.location(in: self)
        let viewsize = self.bounds.size
        let newPoint = CGPoint(x: point.y/viewsize.height, y: 1.0-point.x/viewsize.width)

        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else {
            return
        }

        do {
            try device.lockForConfiguration()
        } catch _ {
            return
        }

        if device.isFocusModeSupported(AVCaptureDevice.FocusMode.autoFocus) == true {
            device.focusMode = AVCaptureDevice.FocusMode.autoFocus
            device.focusPointOfInterest = newPoint
        }

        if device.isExposureModeSupported(AVCaptureDevice.ExposureMode.continuousAutoExposure) == true {
            device.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
            device.exposurePointOfInterest = newPoint
        }

        device.unlockForConfiguration()

        guard let focusView = self.focusView else { return }

        focusView.alpha = 0.0
        focusView.center = point
        focusView.backgroundColor = UIColor.clear
        focusView.layer.borderColor = fusumaBaseTintColor.cgColor
        focusView.layer.borderWidth = 1.0
        focusView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        addSubview(focusView)

        UIView.animate(withDuration: 0.8,
                       delay: 0.0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 3.0,
                       options: UIView.AnimationOptions.curveEaseIn,
                       animations:{
                        focusView.alpha = 1.0
                        focusView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        }, completion: {(finished) in
            focusView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            focusView.removeFromSuperview()
        })
    }

    func flashConfiguration() {

        do {
            if let device = device {
                guard device.hasFlash else { return }

                try device.lockForConfiguration()
                device.flashMode = AVCaptureDevice.FlashMode.off
                flashButton.setImage(flashOffImage?.withRenderingMode(.alwaysTemplate), for: UIControl.State())

                device.unlockForConfiguration()
            }
        } catch _ {
            return
        }
    }

    var cameraIsAvailable: Bool {
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)

        if status == AVAuthorizationStatus.authorized {
            return true
        }

        return false
    }
}
