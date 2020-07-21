//
//  UIImageView+load.swift
//  500pxApiChallenge
//
//  Created by Alexander Mueller on 2020-07-21.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import Foundation
import UIKit

extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self?.backgroundColor = .red
                }
            }
        }
    }
}
