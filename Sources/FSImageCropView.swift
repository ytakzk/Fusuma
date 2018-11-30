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
            guard image != nil else {
                imageView.image = nil
                return
            }

            if !imageView.isDescendant(of: self) {
                imageView.alpha = 1.0
                addSubview(imageView)
            }

            guard fusumaCropImage else {
                imageView.frame = frame
                imageView.contentMode = .scaleAspectFit
                isUserInteractionEnabled = false

                imageView.image = image
                return
            }

            let imageSize = self.imageSize ?? image.size
            let ratioW = frame.width / imageSize.width // 400 / 1000 => 0.4
            let ratioH = frame.height / imageSize.height // 300 / 500 => 0.6

            if ratioH > ratioW {
                imageView.frame = CGRect(
                    origin: CGPoint.zero,
                    size: CGSize(width: imageSize.width  * ratioH, height: frame.height)
                )
            } else {
                imageView.frame = CGRect(
                    origin: CGPoint.zero,
                    size: CGSize(width: frame.width, height: imageSize.height  * ratioW)
                )
            }

            contentOffset = CGPoint(
                x: imageView.center.x - center.x,
                y: imageView.center.y - center.y
            )

            contentSize = CGSize(width: imageView.frame.width + 1, height: imageView.frame.height + 1)

            imageView.image = image

            zoomScale = 1.0
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!

        backgroundColor = fusumaBackgroundColor
        frame.size      = CGSize.zero
        clipsToBounds   = true

        imageView.alpha = 0.0
        imageView.frame = CGRect(origin: CGPoint.zero, size: CGSize.zero)

        maximumZoomScale = 2.0
        minimumZoomScale = 0.8
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator   = false
        bouncesZoom = true
        bounces = true
        scrollsToTop = false
        delegate = self
    }


    func changeScrollable(_ isScrollable: Bool) {
        isScrollEnabled = isScrollable
    }

    // MARK: UIScrollViewDelegate Protocol

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
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

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        contentSize = CGSize(width: imageView.frame.width + 1, height: imageView.frame.height + 1)
    }
}
