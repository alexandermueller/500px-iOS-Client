//
//  UIView+AddSubViewIfNecessary.swift
//  500pxApiChallenge
//
//  Created by Alexander Mueller on 2020-07-24.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func addSubviewIfNecessary(_ view: UIView) {
        if !self.subviews.contains(view) {
            self.addSubview(view)
        }
    }
}
