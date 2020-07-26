//
//  Int+ShortForm.swift
//  500pxApiChallenge
//
//  Created by Alexander Mueller on 2020-07-24.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import Foundation

fileprivate let kAbbreviatedNumberMarkers = ["", "k", "m", "b"]

extension Int {
    /* shortForm:
     * - Returns a 1-3 digit representation of the Integer's value pegged to the nearest power of 1000.
     * - If values matching or exceeding the final marker in the above list are shortened, they are pegged to the
     *   final marker and displayed as "1.0<final_marker>+"
     *
     * ie. 6990 -> "6.99k", 123456 -> "123k", 123 -> "123", 123000123 -> "123m", 4333222111 -> "1.0b+"
     */
    func shortForm() -> String {
        assert(kAbbreviatedNumberMarkers.count > 0)
        
        guard self > 0 else {
            return "0"
        }
        
        let powersOfTen: Int = Int(log10(Double(self)))
        let powersOfThousand: Int = powersOfTen / 3
        
        guard powersOfThousand < kAbbreviatedNumberMarkers.count else {
            return "1.0\(kAbbreviatedNumberMarkers.last ?? "!")+"
        }
        
        let shortened: Double = Double(self) / (pow(10.0, 3 * powersOfThousand) as NSNumber).doubleValue
        
        // Display up to 3 digits without a decimal if the value is < 1000
        if powersOfThousand == 0 {
            return String(Int(shortened))
        }
        
        var shortenedString = ""
        
        // Display the first 3 significant digits of the value (omitting the decimal if there are 3 significant digits ahead of it)
        if powersOfTen % 3 == 2 {
            shortenedString = String(Int(shortened)) + kAbbreviatedNumberMarkers[powersOfThousand]
        } else {
            shortenedString = String(String(shortened).prefix(4)) + kAbbreviatedNumberMarkers[powersOfThousand]
        }
        
        return shortenedString
    }
}
