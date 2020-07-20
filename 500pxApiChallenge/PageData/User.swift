//
//  User.swift
//  500pxApiChallenge
//
//  Created by Alexander Mueller on 2020-07-19.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import Foundation

struct User: Codable {
    var username: String
    var fullname: String
    var userpicUrl: String
    var coverUrl: String?
}
