//
//  UIButton+AnimatesPressActions.swift
//  500pxApiChallenge
//
//  Created by Alexander Mueller on 2020-07-22.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import Foundation
import UIKit

// Taken (and modified slightly) from this slick guide by Rory Bain:
// https://www.roryba.in/programming/swift/2018/03/24/animating-uibutton.html
// This allows the toggling of animations to a UIButton on touch events.

extension UIButton {
    /* animatesPressActions:shouldAnimate:
     * - Adds/removes triggers for animateDown and animateUp on UIButtons for touch actions.
     */
    func animatesPressActions(_ shouldAnimate: Bool) {
        if shouldAnimate {
            addTarget(self, action: #selector(animateDown), for: [.touchDown, .touchDragEnter])
            addTarget(self, action: #selector(animateUp), for: [.touchDragExit, .touchCancel, .touchUpInside, .touchUpOutside])
        } else {
            removeTarget(self, action: #selector(animateDown), for: [.touchDown, .touchDragEnter])
            removeTarget(self, action: #selector(animateUp), for: [.touchDragExit, .touchCancel, .touchUpInside, .touchUpOutside])
        }
    }

    /* animateDown:sender:
     * - Triggers a down press animation on the sender.
     */
    @objc private func animateDown(sender: UIButton) {
        animate(sender, transform: CGAffineTransform.identity.scaledBy(x: 0.95, y: 0.95))
    }

    /* animateUp:sender:
     * - Triggers a lift up animation on the sender.
     */
    @objc private func animateUp(sender: UIButton) {
        animate(sender, transform: .identity)
    }

    /* animate:button:transform:
     * - Convenience function for an animation on a button with predetermined animation settings.
     */
    private func animate(_ button: UIButton, transform: CGAffineTransform) {
        UIView.animate(withDuration: 0.4,
                       delay: 0,
                       usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 3,
                       options: [.curveEaseInOut],
                       animations: { button.transform = transform },
                       completion: nil)
    }
}
