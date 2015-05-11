//
// Created by Dee Madden on 5/10/15.
// Copyright (c) 2015 RGA. All rights reserved.
//

import Foundation
import ObjectiveC
import UIKit

private let _contentFileAssociationKey = malloc(4)

extension UIView {
    var contentFile: String? {
        get {
            let propertyValue : AnyObject! = objc_getAssociatedObject(self, _contentFileAssociationKey)
            return propertyValue as? String
        }
        set {
            objc_setAssociatedObject(self, _contentFileAssociationKey, newValue, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
        }
    }
}