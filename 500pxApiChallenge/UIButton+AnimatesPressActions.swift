//
//  UIButton+AnimatesPressActions.swift
//  500pxApiChallenge
//
//  Created by Alexander Mueller on 2020-07-22.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import Foundation
import UIKit

// Shamelessly borrowed (and modified slightly) from this slick guide by Rory Bain:
// https://www.roryba.in/programming/swift/2018/03/24/animating-uibutton.html
// This allows the toggling of animations to a UIButton on touch events.
// Thanks, Rory! :)

extension UIButton {
    func animatesPressActions(_ shouldAnimate: Bool) {
        if shouldAnimate {
            addTarget(self, action: #selector(animateDown), for: [.touchDown, .touchDragEnter])
            addTarget(self, action: #selector(animateUp), for: [.touchDragExit, .touchCancel, .touchUpInside, .touchUpOutside])
        } else {
            removeTarget(self, action: #selector(animateDown), for: [.touchDown, .touchDragEnter])
            removeTarget(self, action: #selector(animateUp), for: [.touchDragExit, .touchCancel, .touchUpInside, .touchUpOutside])
        }
    }

    @objc private func animateDown(sender: UIButton) {
        animate(sender, transform: CGAffineTransform.identity.scaledBy(x: 0.95, y: 0.95))
    }

    @objc private func animateUp(sender: UIButton) {
        animate(sender, transform: .identity)
    }

    private func animate(_ button: UIButton, transform: CGAffineTransform) {
        UIView.animate(withDuration: 0.4,
                       delay: 0,
                       usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 3,
                       options: [.curveEaseInOut],
                       animations: { button.transform = transform},
                       completion: nil)
    }
}
