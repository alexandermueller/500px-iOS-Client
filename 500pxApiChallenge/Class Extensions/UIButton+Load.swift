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
    /* load:imageURL:
     * - Fetches the images at the given url on a background thread, setting it
     *   on success to the UIButton's image view.
     */
    func load(imageURL: URL?) {
        DispatchQueue.global().async { [weak self] in
            do {
                if let url = imageURL {
                    let data = try Data(contentsOf: url)
                    if let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self?.setImage(image, for: .normal)
                        }
                    }
                }
            } catch {
                // It would be perfect to set a placeholder here, or even have the image disappear from the scrollview.
                print(error)
            }
        }
    }
}
