//
//  ImageData.swift
//  500pxApiChallenge
//
//  Created by Alex Mueller on 2020-07-17.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import Foundation

struct Image: Codable {
    var url: String
    var title: String
    var author: String
    var date: String
    var description: String
}
