//
//  UIImageOrientationFix.swift
//  FridgeTracker
//
//  Created by Sébastien POIVRE on 06/08/2017.
//  Copyright © 2017 Sébastien POIVRE. All rights reserved.
//

import Foundation
import UIKit
// Source: https://stackoverflow.com/questions/10307521/ios-png-image-rotated-90-degrees?rq=1

extension UIImage {
    func correctlyOrientedImage() -> UIImage? {
        if self.imageOrientation == UIImageOrientation.up {
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        self.draw(in: CGRect(x:0, y:0, width:self.size.width, height:self.size.height))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return normalizedImage;
    }
}
