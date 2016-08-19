//
//  ViewController.swift
//  Fusuma
//
//  Created by ytakzk on 01/31/2016.
//  Copyright (c) 2016 ytakzk. All rights reserved.
//

import UIKit

class ViewController: UIViewController, FusumaDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var showButton: UIButton!
    
    @IBOutlet weak var fileUrlLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        showButton.layer.cornerRadius = 2.0
        self.fileUrlLabel.text = ""
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func showButtonPressed(sender: UIButton) {
        
        // Show Fusuma
        let fusuma = FusumaViewController()
        
        // fusumaCropImage = false

        fusuma.delegate = self
        self.presentViewController(fusuma, animated: true, completion: nil)
        
    }
    
    // MARK: FusumaDelegate Protocol
  func fusuma(fusuma: FusumaViewController, imageSelected image: UIImage, viaMode mode: Int) {
        print("Image selected")
        imageView.image = image
        self.dismissViewControllerAnimated(true, completion: nil)
    }
      
    func fusuma(fusuma: FusumaViewController, videoCompletedWithFileURL fileURL: NSURL) {
        print("video completed and output to file: \(fileURL)")
        self.fileUrlLabel.text = "file output to: \(fileURL.absoluteString)"
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    
    func fusumaCameraRollUnauthorized(fusuma: FusumaViewController) {

        self.dismissViewControllerAnimated(true, completion: nil)

        print("Camera roll unauthorized")

        let alert = UIAlertController(title: "Access Requested", message: "Saving image needs to access your photo album", preferredStyle: .Alert)

        alert.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { (action) -> Void in

          if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
            UIApplication.sharedApplication().openURL(url)
          }

        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action) -> Void in

        }))

        self.presentViewController(alert, animated: true, completion: nil)
    }

    func fusumaClosed(fusuma: FusumaViewController) {
        print("Called when the close button is pressed")
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}

