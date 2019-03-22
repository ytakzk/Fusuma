//
//  FSVideoCameraView.swift
//  Fusuma
//
//  Created by Brendan Kirchner on 3/18/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import AVFoundation

@objc protocol FSVideoCameraViewDelegate: class {
    func videoFinished(withFileURL fileURL: URL)
}

final class FSVideoCameraView: UIView {
    @IBOutlet weak var previewViewContainer: UIView!
    @IBOutlet weak var shotButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var flipButton: UIButton!

    weak var delegate: FSVideoCameraViewDelegate? = nil

    var recordedOrientation = UIDeviceOrientation.portrait
    
    var session: AVCaptureSession?
    var device: AVCaptureDevice?
    var videoInput: AVCaptureDeviceInput?
    var videoOutput: AVCaptureMovieFileOutput?
    var focusView: UIView?

    var flashOffImage: UIImage?
    var flashOnImage: UIImage?
    var videoStartImage: UIImage?
    var videoStopImage: UIImage?

    private var zoomFactor: CGFloat = 1.0
    private var isRecording = false

    static func instance() -> FSVideoCameraView {
        return UINib(nibName: "FSVideoCameraView", bundle: Bundle(for: self.classForCoder())).instantiate(withOwner: self, options: nil)[0] as! FSVideoCameraView
    }

    func initialize() {
        if session != nil { return }

        backgroundColor = fusumaBackgroundColor

        isHidden = false

        // AVCapture
        session = AVCaptureSession()

        guard let session = session else { return }

        for device in AVCaptureDevice.devices() {
            if device.position == AVCaptureDevice.Position.back {
                self.device = device
                break
            }
        }

        guard let device = device else { return }

       do {
            videoInput = try AVCaptureDeviceInput(device: device)

            session.addInput(videoInput!)

            videoOutput = AVCaptureMovieFileOutput()

            // add audio conditionally
            if let audioDevice = AVCaptureDevice.default(for: .audio) {
                if let audioInput = try? AVCaptureDeviceInput(device: audioDevice) {
                    if session.canAddInput(audioInput) {
                        session.addInput(audioInput)
                    }
                }
            }


            let totalSeconds = 10.0 //Total Seconds of capture time
            let timeScale: Int32 = 30 //FPS
//
////            if videoOutput!.availableVideoCodecTypes.contains(.h264) {
//                // Use the H.264 codec to encode the video.
//            videoOutput!.setOutputSettings([AVVideoCodecKey:  AVVideoCodecType.h264], for: videoOutput!.connection(with: AVMediaType.video)!)
////            }
//
            let maxDuration = CMTimeMakeWithSeconds(totalSeconds, preferredTimescale: timeScale)

            videoOutput?.maxRecordedDuration = maxDuration
            // 35 mb
            videoOutput?.minFreeDiskSpaceLimit = 35 * 1024 * 1024 //SET MIN FREE SPACE IN BYTES FOR RECORDING TO CONTINUE ON A VOLUME

            if session.canAddOutput(videoOutput!) {
                session.addOutput(videoOutput!)
            }

            let videoLayer = AVCaptureVideoPreviewLayer(session: session)
            videoLayer.frame = self.previewViewContainer.bounds
            videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill

            previewViewContainer.layer.addSublayer(videoLayer)

            session.startRunning()

            // Focus View
            focusView = UIView(frame: CGRect(x: 0, y: 0, width: 90, height: 90))
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(FSVideoCameraView.focus(_:)))
            previewViewContainer.addGestureRecognizer(tapRecognizer)
        } catch {
        }

        let bundle = Bundle(for: self.classForCoder)

        flashOnImage = fusumaFlashOnImage != nil ? fusumaFlashOnImage : UIImage(named: "ic_flash_on", in: bundle, compatibleWith: nil)
        flashOffImage = fusumaFlashOffImage != nil ? fusumaFlashOffImage : UIImage(named: "ic_flash_off", in: bundle, compatibleWith: nil)
        let flipImage = fusumaFlipImage != nil ? fusumaFlipImage : UIImage(named: "ic_loop", in: bundle, compatibleWith: nil)
        videoStartImage = fusumaVideoStartImage != nil ? fusumaVideoStartImage : UIImage(named: "ic_shutter", in: bundle, compatibleWith: nil)
        videoStopImage = fusumaVideoStopImage != nil ? fusumaVideoStopImage : UIImage(named: "ic_shutter_recording", in: bundle, compatibleWith: nil)

        flashButton.tintColor = fusumaBaseTintColor
        flipButton.tintColor  = fusumaBaseTintColor
        shotButton.tintColor  = fusumaBaseTintColor

        flashButton.setImage(flashOffImage?.withRenderingMode(.alwaysTemplate), for: .normal)
        flipButton.setImage(flipImage?.withRenderingMode(.alwaysTemplate), for: .normal)
        shotButton.setImage(videoStartImage?.withRenderingMode(.alwaysTemplate), for: .normal)

        flashConfiguration()
        startCamera()

        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchToZoom))
        previewViewContainer.addGestureRecognizer(pinchGestureRecognizer)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func startCamera() {
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)

        if status == AVAuthorizationStatus.authorized {
            session?.startRunning()
        } else if status == AVAuthorizationStatus.denied ||
            status == AVAuthorizationStatus.restricted {
            session?.stopRunning()
        }
    }

    func stopCamera() {
        if isRecording {
            toggleRecording()
        }

        session?.stopRunning()
    }

    @IBAction func shotButtonPressed(_ sender: UIButton) {
        toggleRecording()
    }

    @IBAction func flipButtonPressed(_ sender: UIButton) {
        guard let session = session else { return }

        session.stopRunning()

        do {
            session.beginConfiguration()

            for input in session.inputs {
                session.removeInput(input)
            }

            let position = videoInput?.device.position == AVCaptureDevice.Position.front ? AVCaptureDevice.Position.back : AVCaptureDevice.Position.front

            for device in AVCaptureDevice.devices(for: AVMediaType.video) {
                if device.position == position {
                    videoInput = try AVCaptureDeviceInput(device: device)
                    session.addInput(videoInput!)
                }
            }

            session.commitConfiguration()
        } catch {
        }

        session.startRunning()
    }

    @IBAction func flashButtonPressed(_ sender: UIButton) {
        do {
            guard let device = device else { return }

            try device.lockForConfiguration()

            let mode = device.flashMode

            switch mode {
            case .off:
                device.flashMode = AVCaptureDevice.FlashMode.on
                flashButton.setImage(flashOnImage, for: UIControl.State())
            case .on:
                device.flashMode = AVCaptureDevice.FlashMode.off
                flashButton.setImage(flashOffImage, for: UIControl.State())
            default:
                break
            }

            device.unlockForConfiguration()
        } catch _ {
            flashButton.setImage(flashOffImage, for: UIControl.State())
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

extension AVAsset {
    
    var g_size: CGSize {
        return tracks(withMediaType: AVMediaType.video).first?.naturalSize ?? .zero
    }
    
    var g_orientation: UIInterfaceOrientation {
        
        guard let transform = tracks(withMediaType: AVMediaType.video).first?.preferredTransform else {
            return .portrait
        }
        
        switch (transform.tx, transform.ty) {
        case (0, 0):
            return .landscapeRight
        case (g_size.width, g_size.height):
            return .landscapeLeft
        case (0, g_size.width):
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
}

extension FSVideoCameraView: AVCaptureFileOutputRecordingDelegate {
    
    
    func fileOutput(_ captureOutput: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("started recording to: \(fileURL)")
        recordedOrientation = UIDevice.current.orientation
    }

    func replaceMovURL(u: URL) -> URL {
        return u.deletingPathExtension().appendingPathExtension("mp4")
    }
    func _getDataFor(_ item: AVPlayerItem, completion: @escaping (URL?) -> ()) {

        guard item.asset.isExportable else {
            completion(nil)
            return
        }

        let composition = AVMutableComposition()
        let compositionVideoTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: CMPersistentTrackID(kCMPersistentTrackID_Invalid))
        let compositionAudioTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: CMPersistentTrackID(kCMPersistentTrackID_Invalid))

        let sourceVideoTrack = item.asset.tracks(withMediaType: AVMediaType.video).first!
        let sourceAudioTrack = item.asset.tracks(withMediaType: AVMediaType.audio).first!
        
        do {
            try compositionVideoTrack!.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: item.asset.duration), of: sourceVideoTrack, at: CMTime.zero)
            try compositionAudioTrack!.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: item.asset.duration), of: sourceAudioTrack, at: CMTime.zero)
        } catch let error1 as NSError {
            print(error1)
//            error = error1
            completion(nil)
            return
        } catch {
            print(error)
            completion(nil)
            return
        }

        // rotate if necessary
        if recordedOrientation == .portrait || recordedOrientation == .portraitUpsideDown {
            let rotationTransform = CGAffineTransform(rotationAngle: CGFloat(Double.pi / 2));
            compositionVideoTrack!.preferredTransform = rotationTransform;
        } else if recordedOrientation == .landscapeRight {
            let rotationTransform = CGAffineTransform(rotationAngle: CGFloat(Double.pi));
            compositionVideoTrack!.preferredTransform = rotationTransform;

        }
        
        
        
        let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: composition)
        var preset: String = AVAssetExportPresetPassthrough
        if compatiblePresets.contains(AVAssetExportPreset1920x1080) { preset = AVAssetExportPreset1920x1080 }

        guard
            let exportSession = AVAssetExportSession(asset: composition, presetName: preset),
            exportSession.supportedFileTypes.contains(AVFileType.mp4) else {
                completion(nil)
                return
        }

        var tempFileUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("temp_video_data.mp4", isDirectory: false)
        tempFileUrl = URL(fileURLWithPath: tempFileUrl.path)

        exportSession.outputURL = tempFileUrl
        exportSession.outputFileType = AVFileType.mp4
        let startTime = CMTimeMake(value: 0, timescale: 1)
        let timeRange = CMTimeRangeMake(start: startTime, duration: item.duration)
        exportSession.timeRange = timeRange

        do { // delete old video
            try FileManager.default.removeItem(at: tempFileUrl)
        } catch { print(error.localizedDescription) }

        exportSession.exportAsynchronously {
            print("\(tempFileUrl)")
            print("\(String(describing: exportSession.error))")
            _ = try? Data(contentsOf: tempFileUrl)
//            _ = try? FileManager.default.removeItem(at: tempFileUrl)
            completion(tempFileUrl)
        }
    }

    func fileOutput(_ captureOutput: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("finished recording to: \(outputFileURL)")

        let asset = AVURLAsset(url: outputFileURL)
        let item = AVPlayerItem(asset: asset)

        self._getDataFor(item, completion: ({ (url) in
            
            DispatchQueue.main.async {
                if let u = url {
                    self.delegate?.videoFinished(withFileURL: u)
                }
            }

        }))


//        // These settings will encode using H.264.
//        let preset = AVAssetExportPreset1920x1080
//        let outFileType = AVFileType.mp4
//
//        let anAsset = AVAsset(url: outputFileURL)
//
//        AVAssetExportSession.determineCompatibility(ofExportPreset: preset, with: anAsset, outputFileType: outFileType, completionHandler: { (isCompatible) in
//            if !isCompatible {
//                return
//            }
//            guard let export = AVAssetExportSession(asset: anAsset, presetName: preset) else {
//                return
//            }
//
//            let newurl = self.replaceMovURL(u: outputFileURL)
//
//            DispatchQueue.main.async {
//
//                export.outputFileType = outFileType
//                export.outputURL = newurl
//                export.exportAsynchronously { () -> Void in
//                    // Handle export results.
//                    if let err = export.error {
//
//                    } else {
//                        DispatchQueue.main.async {
//                             self.delegate?.videoFinished(withFileURL: newurl)
//                        }
//                    }
//                }
//            }
//        })


    }
}

fileprivate extension FSVideoCameraView {
    func toggleRecording() {
        guard let videoOutput = videoOutput else { return }

        isRecording = !isRecording

        let shotImage = isRecording ? videoStopImage : videoStartImage

        self.shotButton.setImage(shotImage, for: UIControl.State())

        if isRecording {
            let outputPath = "\(NSTemporaryDirectory())output.mov"
            let outputURL = URL(fileURLWithPath: outputPath)

            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: outputPath) {
                do {
                    try fileManager.removeItem(atPath: outputPath)
                } catch {
                    print("error removing item at path: \(outputPath)")
                    self.isRecording = false
                    return
                }
            }

            flipButton.isEnabled = false
            flashButton.isEnabled = false
            videoOutput.startRecording(to: outputURL, recordingDelegate: self)
        } else {
            videoOutput.stopRecording()
            flipButton.isEnabled = true
            flashButton.isEnabled = true
        }
    }

    @objc func focus(_ recognizer: UITapGestureRecognizer) {
        let point    = recognizer.location(in: self)
        let viewsize = self.bounds.size
        let newPoint = CGPoint(x: point.y / viewsize.height, y: 1.0-point.x / viewsize.width)

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

        guard let focusView = focusView else { return }

        focusView.alpha  = 0.0
        focusView.center = point
        focusView.backgroundColor   = UIColor.clear
        focusView.layer.borderColor = UIColor.white.cgColor
        focusView.layer.borderWidth = 1.0
        focusView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        addSubview(focusView)

        UIView.animate(
            withDuration: 0.8,
            delay: 0.0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 3.0,
            options: UIView.AnimationOptions.curveEaseIn,
            animations: {
                focusView.alpha = 1.0
                focusView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        }, completion: { finished in
            focusView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            focusView.removeFromSuperview()
        })
    }

    func flashConfiguration() {
        do {
            guard let device = device else { return }
            guard device.hasFlash else { return }

            try device.lockForConfiguration()

            device.flashMode = AVCaptureDevice.FlashMode.off
            flashButton.setImage(flashOffImage, for: UIControl.State())

            device.unlockForConfiguration()
        } catch _ {
            return
        }
    }
}
