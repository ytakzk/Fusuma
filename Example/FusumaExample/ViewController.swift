//
//  ViewController.swift
//  Fusuma
//
//  Created by ytakzk on 01/31/2016.
//  Copyright (c) 2016 ytakzk. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    // UI Properties
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var showButton: UIButton!
    @IBOutlet weak var fileUrlLabel: UILabel!

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Setups
    fileprivate func setupComponets() {
        // showButton
        showButton.layer.cornerRadius = 2.0

        // fileUrlLabel
        fileUrlLabel.text = ""
    }

    // MARK: - UI Actions
    @IBAction func showButtonPressed(_ sender: AnyObject) {
        let fusuma = FusumaViewController()
        fusuma.delegate = self
        self.present(fusuma, animated: true, completion: nil)
    }
}

// MARK: - FusumaDelegate
extension ViewController: FusumaDelegate {

    func fusumaImageSelected(_ image: UIImage, source: FusumaMode) {
        switch source {
        case .camera:
            print("Image captured from Camera")
        case .library:
            print("Image selected from Camera Roll")
        default:
            print("Image selected")
        }
        imageView.image = image
    }

    func fusumaImageSelected(_ image: UIImage, source: FusumaMode, metaData: ImageMetadata) {
        print("Image mediatype: \(metaData.mediaType)")
        print("Source image size: \(metaData.pixelWidth)x\(metaData.pixelHeight)")
        print("Creation date: \(metaData.creationDate)")
        print("Modification date: \(metaData.modificationDate)")
        print("Video duration: \(metaData.duration)")
        print("Is favourite: \(metaData.isFavourite)")
        print("Is hidden: \(metaData.isHidden)")
        print("Location: \(metaData.location)")
    }

    func fusumaVideoCompleted(withFileURL fileURL: URL) {
        print("video completed and output to file: \(fileURL)")
        self.fileUrlLabel.text = "file output to: \(fileURL.absoluteString)"
    }
    
    func fusumaDismissedWithImage(_ image: UIImage, source: FusumaMode) {
        switch source {
        case .camera:
            print("Called just after dismissed FusumaViewController using Camera")
        case .library:
            print("Called just after dismissed FusumaViewController using Camera Roll")
        default:
            print("Called just after dismissed FusumaViewController")
        }
    }
    
    func fusumaCameraRollUnauthorized() {
        print("Camera roll unauthorized")
        let alert = UIAlertController(title: "Access Requested", message: "Saving image needs to access your photo album", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { (action) -> Void in
            if let url = URL(string:UIApplicationOpenSettingsURLString) {
                UIApplication.shared.openURL(url)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
            
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func fusumaClosed() {
        print("Called when the FusumaViewController disappeared")
    }
    
    func fusumaWillClosed() {
        print("Called when the close button is pressed")
    }
}
