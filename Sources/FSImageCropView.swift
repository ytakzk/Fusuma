//
//  FZImageCropView.swift
//  Fusuma
//
//  Created by Yuta Akizuki on 2015/11/16.
//  Copyright © 2015年 ytakzk. All rights reserved.
//

import UIKit

final class FSImageCropView: UIScrollView, UIScrollViewDelegate {
    
    var imageView = UIImageView()
    
    var imageSize: CGSize?
    
    var image: UIImage! = nil {
        
        didSet {
            
            if image != nil {
                
                if !imageView.isDescendantOfView(self) {
                    self.imageView.alpha = 1.0
                    self.addSubview(imageView)
                }
                
            } else {
                
                imageView.image = nil
                return
            }
            
            if !fusumaCropImage {
                // Disable scroll view and set image to fit in view
                imageView.frame = self.frame
                imageView.contentMode = .ScaleAspectFit
                self.userInteractionEnabled = false

                imageView.image = image
                return
            }

            let imageSize = self.imageSize ?? image.size
            
            if imageSize.width < self.frame.width || imageSize.height < self.frame.height {
                
                // The width or height of the image is smaller than the frame size
                
                if imageSize.width > imageSize.height {
                    
                    // Width > Height
                    
                    let ratio = self.frame.width / imageSize.width
                    
                    imageView.frame = CGRect(
                        origin: CGPointZero,
                        size: CGSize(width: self.frame.width, height: imageSize.height * ratio)
                    )
                    
                } else {
                    
                    // Width <= Height
                    
                    let ratio = self.frame.height / imageSize.height
                    
                    imageView.frame = CGRect(
                        origin: CGPointZero,
                        size: CGSize(width: imageSize.width * ratio, height: self.frame.size.height)
                    )
                    
                }
                
                imageView.center = self.center
                
            } else {

                // The width or height of the image is bigger than the frame size

                if imageSize.width > imageSize.height {
                    
                    // Width > Height
                    
                    let ratio = self.frame.height / imageSize.height
                    
                    imageView.frame = CGRect(
                        origin: CGPointZero,
                        size: CGSize(width: imageSize.width * ratio, height: self.frame.height)
                    )
                    
                } else {
                    
                    // Width <= Height

                    let ratio = self.frame.width / imageSize.width
                    
                    imageView.frame = CGRect(
                        origin: CGPointZero,
                        size: CGSize(width: self.frame.width, height: imageSize.height * ratio)
                    )
                    
                }
                
                self.contentOffset = CGPoint(
                    x: imageView.center.x - self.center.x,
                    y: imageView.center.y - self.center.y
                )
            }
            
            self.contentSize = CGSize(width: imageView.frame.width + 1, height: imageView.frame.height + 1)
            
            imageView.image = image
            
            self.zoomScale = 1.0
            
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)!
        
        self.backgroundColor = fusumaBackgroundColor
        self.frame.size      = CGSizeZero
        self.clipsToBounds   = true
        self.imageView.alpha = 0.0
        
        imageView.frame = CGRect(origin: CGPointZero, size: CGSizeZero)
        
        self.maximumZoomScale = 2.0
        self.minimumZoomScale = 0.8
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator   = false
        self.bouncesZoom = true
        self.bounces = true
        
        self.delegate = self
    }
    
    
    func changeScrollable(isScrollable: Bool) {
        
        self.scrollEnabled = isScrollable
    }
    
    // MARK: UIScrollViewDelegate Protocol
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        
        return imageView

    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        
        let boundsSize = scrollView.bounds.size
        var contentsFrame = imageView.frame
        
        if contentsFrame.size.width < boundsSize.width {
            
            contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0
            
        } else {
            contentsFrame.origin.x = 0.0
        }
        
        if contentsFrame.size.height < boundsSize.height {
            
            contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0
        } else {
            
            contentsFrame.origin.y = 0.0
        }
        
        imageView.frame = contentsFrame
        
    }
    
    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) {
        
        self.contentSize = CGSize(width: imageView.frame.width + 1, height: imageView.frame.height + 1)
    }
    
}