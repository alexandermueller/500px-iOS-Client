//
//  UIButton+Load.swift
//  500pxApiChallenge
//
//  Created by Alexander Mueller on 2020-07-21.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import Foundation
import UIKit

// Taken from this guide (and modified slightly) by Paul Hudson:
// https://www.hackingwithswift.com/example-code/uikit/how-to-load-a-remote-image-url-into-uiimageview

extension UIButton {
    func load(lowestSizeURL: URL?, largestSizeURL: URL?) {
        var urls: [(URL, Bool)] = []
        
        if let lowestURL = lowestSizeURL {
            urls += [(lowestURL, true)]
        }
        
        if let largestURL = largestSizeURL, lowestSizeURL != largestSizeURL {
            urls += [(largestURL, false)]
        }
        
        DispatchQueue.global().async { [weak self] in
            do {
                for (url, isLowestSize) in urls {
                    let data = try Data(contentsOf: url)
                    if let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self?.setImage(image, for: isLowestSize ? .normal : .reserved)
                        }
                    }
                }
            } catch {
                print(error)
            }
        }
    }
}
