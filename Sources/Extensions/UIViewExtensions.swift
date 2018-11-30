//
//  UIViewExtensions.swift
//  Fusuma
//
//  Created by Nick Kezhaya on 11/30/18.
//  Copyright © 2018 ytakzk. All rights reserved.
//

import UIKit

extension UIView {
    func addBottomBorder(_ color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.borderColor = color.cgColor
        border.frame = CGRect(x: 0, y: frame.size.height - width, width: UIScreen.main.bounds.size.width, height: width)
        border.borderWidth = width
        layer.addSublayer(border)
    }
}
