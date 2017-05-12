//
//  HelperMethods.swift
//  Fusuma
//
//  Created by Bohdan Shcherbyna on 5/9/17.
//  Copyright © 2017 ytakzk. All rights reserved.
//

import UIKit

class FusumaHelper {
    
    class func stringFromTimeInterval(interval: TimeInterval) -> String {
        
        let ti = NSInteger(interval)
        
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours = (ti / 3600)
        
        return String(format: "%0.2d:%0.2d:%0.2d",hours,minutes,seconds)
    }
    
}
