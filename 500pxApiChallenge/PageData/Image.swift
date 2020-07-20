//
//  Image.swift
//  500pxApiChallenge
//
//  Created by Alexander Mueller on 2020-07-19.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import Foundation

struct Image: Codable {
    var format: String
    var size: Int
    var url: String
    var httpsUrl: String
}
