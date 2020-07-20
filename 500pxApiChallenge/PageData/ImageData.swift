//
//  ImageData.swift
//  500pxApiChallenge
//
//  Created by Alex Mueller on 2020-07-17.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import Foundation

struct ImageData: Codable {
    var name: String
    var user: User
    var description: String
    var createdAt: String
    var commentsCount: Int
    var votesCount: Int
    var positiveVotesCount: Int
    var timesViewed: Int
    var images: [Image]
}
