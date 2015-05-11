//
// Created by Dee Madden on 5/10/15.
// Copyright (c) 2015 RGA. All rights reserved.
//

import Foundation

extension String {
    func beginsWith (str: String) -> Bool {
        if let range = self.rangeOfString(str) {
            return range.startIndex == self.startIndex
        }
        return false
    }

    func endsWith (str: String) -> Bool {
        if let range = self.rangeOfString(str) {
            return range.endIndex == self.endIndex
        }
        return false
    }
}