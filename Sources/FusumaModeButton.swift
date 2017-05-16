//
//  FusumaModeButton.swift
//  Fusuma
//
//  Created by Bohdan Shcherbyna on 5/16/17.
//  Copyright © 2017 ytakzk. All rights reserved.
//

import UIKit

class FusumaModeButton: UIButton {

    override var isSelected: Bool {
        didSet {
            updateView()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateView()
    }
    
    //MARK: - Set Selected
    
    func updateView() {
        if self.isSelected {
            self.addBottomBorder(fusumaTintColor, width: 3)
            self.tintColor = fusumaTintColor
        } else {
            if let sublayers = self.layer.sublayers {
                for layer in sublayers {
                    if let borderColor = layer.borderColor , UIColor(cgColor: borderColor) == fusumaTintColor {
                        layer.removeFromSuperlayer()
                    }
                }
            }
            self.tintColor = fusumaBaseTintColor
        }
    }

}
