//
//  Int+ShortFormTests.swift
//  500pxApiChallengeTests
//
//  Created by Alexander Mueller on 2020-07-26.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import XCTest
@testable import _00pxApiChallenge

typealias UnitTest = (input: Int, output: String)

class Int_ShortFormTests: XCTestCase {
    func testShortForm() {
        let testSuite: [UnitTest] = [
            UnitTest(Int.min, "0"),
            UnitTest(-1, "0"),
            UnitTest(0, "0"),
            UnitTest(999, "999"),
            UnitTest(1000, "1.0k"),
            UnitTest(1001, "1.0k"),
            UnitTest(1021, "1.02k"),
            UnitTest(1221, "1.22k"),
            UnitTest(10000, "10.0k"),
            UnitTest(10221, "10.2k"),
            UnitTest(100122, "100k"),
            UnitTest(101122, "101k"),
            UnitTest(1000000, "1.0m"),
            UnitTest(1000100, "1.0m"),
            UnitTest(1001000, "1.0m"),
            UnitTest(1010000, "1.01m"),
            UnitTest(1100000, "1.1m"),
            UnitTest(1110000, "1.11m"),
            UnitTest(10010000, "10.0m"),
            UnitTest(10110000, "10.1m"),
            UnitTest(100110000, "100m"),
            UnitTest(1000000000, "1.0b+"),
            UnitTest(1000000001, "1.0b+"),
            UnitTest(1000100000, "1.0b+"),
            UnitTest(Int.max, "1.0b+"),
        ]
        
        for (index, test) in testSuite.enumerated() {
            let result = test.input.shortForm()
            XCTAssert(result == test.output, "Test \(index + 1) Failed:\nExpected: \(test.output)\n\t Saw: \(result)")
        }
    }
}
