//
//  Rotatable.swift
//  Burpple2
//
//  Created by Valent Richie on 25/8/16.
//  Copyright © 2016 Burpple Pte Ltd. All rights reserved.
//

import UIKit

@objc public protocol Rotatable {
    var duration: Double { get set }

    func upsideDown(_ animation: Bool)
    func normal(_ animation: Bool)
}

public extension Rotatable where Self: UIView {

    // Default upside down implementation
    func upsideDown(_ animation: Bool) {
        let angle = CGFloat(Double.pi)
        if animation == false {
            transform = CGAffineTransform(rotationAngle: angle)
        } else {
            UIView.animate(withDuration: duration, animations: {
                self.transform = CGAffineTransform(rotationAngle: angle)
            })
        }
    }

    func normal(_ animation: Bool) {
        let angle: CGFloat = 0 // Normal direction

        // The rotation transform will rotate in the direction of shortest angle change
        // If the angle is the same, the default direction is clockwise (which is undesired in this case since the rotation upside down is clockwise)
        // Transform the initial angle to be slightly less than M_PI to make the rotation direction counter clockwise
        let startAngle = CGFloat(Double.pi - 0.001)
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
