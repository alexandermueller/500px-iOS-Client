//
//  UIButton+load.swift
//  500pxApiChallenge
//
//  Created by Alexander Mueller on 2020-07-21.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import Foundation
import UIKit

extension UIButton {
    func load(linkURL: URL?) {
        guard let url = linkURL else {
            return
        }
        
        DispatchQueue.global().async { [weak self] in
            do {
                let data = try Data(contentsOf: url)
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.setBackgroundImage(image, for: .normal)
                        self?.imageView?.contentMode = .scaleAspectFill
                    }
                }
            } catch {
                print(error)
            }
        }
    }
}
