//
//  UIImage_Orientation.swift
//  AutoFaceSaver
//
//  Created by Aleksandr Salo on 12/21/14.
//  Copyright (c) 2014 Aleksandr Salo. All rights reserved.
//

import UIKit

public extension UIImage {
    
    public class func orientationPropertyValueFromImageOrientation(imageOrientation: UIImageOrientation) -> Int {
        var orientation: Int = 0
        switch imageOrientation {
        case .Up:
            orientation = 1
        case .Down:
            orientation = 3
        case .Left:
            orientation = 8
        case .Right:
            orientation = 6
        case .UpMirrored:
            orientation = 2
        case .DownMirrored:
            orientation = 4
        case .LeftMirrored:
            orientation = 5
        case .RightMirrored:
            orientation = 7
        }
        return orientation
    }
    
    public func orientationPropertyValueFromImageOrientation() -> Int {
        return self.dynamicType.orientationPropertyValueFromImageOrientation(self.imageOrientation)
    }
    
}