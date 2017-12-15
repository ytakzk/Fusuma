//
//  ArrowImageView.swift
//  Burpple2
//
//  Created by Valent Richie on 25/8/16.
//  Copyright © 2016 Burpple Pte Ltd. All rights reserved.
//

import UIKit

@objc final class ArrowImageView: UIImageView, Rotatable {

    var duration: Double = 0.3

    func setup() {
        transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi / 2))
        translatesAutoresizingMaskIntoConstraints = false
        setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
        setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
        setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)
        setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        
        if #available(iOS 9.0, *) {
            self.addConstraint(NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 12.0))
            self.addConstraint(NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 6.0))
        }
    }

    init() {
        // ic_arrow is right facing
        super.init(image: UIImage(named: "ic_arrow"))
        setup()
    }

    init(template: Bool) {
        let image = UIImage(named: "ic_arrow")
        if template {
            image?.withRenderingMode(.alwaysTemplate)
        }
        super.init(image: image)
        setup()
    }

    required init?(coder _: NSCoder) {
        super.init(image: UIImage(named: "ic_arrow"))
        setup()
    }

    public func upsideDown(_ animation: Bool) {
        let angle = CGFloat(3 * Double.pi / 2) // Upside down
        if animation == false {
            transform = CGAffineTransform(rotationAngle: angle)
        } else {
            UIView.animate(withDuration: duration, animations: {
                self.transform = CGAffineTransform(rotationAngle: angle)
            })
        }
    }

    public func normal(_ animation: Bool) {
        let angle: CGFloat = CGFloat(Double.pi / 2) // Normal direction

        // The rotation transform will rotate in the direction of shortest angle change
        // If the angle is the same, the default direction is clockwise (which is undesired in this case since the rotation upside down is clockwise)
        // Transform the initial angle to be slightly less than M_PI to make the rotation direction counter clockwise
        let startAngle = CGFloat(3 * Double.pi / 2 - 0.001)
        transform = CGAffineTransform(rotationAngle: startAngle)

        if animation == false {
            transform = CGAffineTransform(rotationAngle: angle)
        } else {
            UIView.animate(withDuration: duration, animations: {
                self.transform = CGAffineTransform(rotationAngle: angle)
            })
        }
    }
}
