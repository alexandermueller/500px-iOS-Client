//
//  PageData.swift
//  500pxApiChallenge
//
//  Created by Alexander Mueller on 2020-07-19.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import Foundation

struct PageData: Codable {
    var currentPage: Int
    var totalPages: Int
    var totalItems: Int
    var feature: String
    var photos: [ImageData]
    
    static func defaultPageData() -> PageData {
        return PageData(currentPage: 1, totalPages: 1, totalItems: 0, feature: "", photos: [])
    }
}
