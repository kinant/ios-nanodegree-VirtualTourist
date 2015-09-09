//
//  Utils.swift
//  Virtual Tourist
//
//  Created by Kinan Turjman on 9/8/15.
//  Copyright (c) 2015 Kinan Turman. All rights reserved.
//

import Foundation

extension String {
    func toDouble() -> Double? {
        return NSNumberFormatter().numberFromString(self)?.doubleValue
    }
}
