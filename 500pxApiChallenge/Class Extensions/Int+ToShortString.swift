//
//  Int+ToShortString.swift
//  500pxApiChallenge
//
//  Created by Alexander Mueller on 2020-07-24.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import Foundation

fileprivate let kAbbreviatedNumberMarkers = ["", "k", "m", "b", "t"]

extension Int {
    func toShortString() -> String {
        assert(kAbbreviatedNumberMarkers.count > 0)
        
        guard self > 0 else {
            return "0"
        }
        
        let powersOfTen: Int = Int(log10(Double(self)))
        let powersOfThousand: Int = powersOfTen / 3
        
        guard powersOfThousand < kAbbreviatedNumberMarkers.count else {
            return "1.0+\(kAbbreviatedNumberMarkers.last ?? "!")"
        }
        
        let shortened: Double = Double(self) / (pow(10.0, 3 * powersOfThousand) as NSNumber).doubleValue
        
        if powersOfThousand == 0 {
            return String(Int(shortened))
        }
        
        var shortenedString = ""
        
        switch powersOfTen % 3 {
        case 2:
            shortenedString = String(Int(shortened)) + kAbbreviatedNumberMarkers[powersOfThousand]
        case 1, 0:
            shortenedString = String(String(shortened).prefix(4)) + kAbbreviatedNumberMarkers[powersOfThousand]
        default:
            return "0"
        }
        
        return shortenedString
    }
}
