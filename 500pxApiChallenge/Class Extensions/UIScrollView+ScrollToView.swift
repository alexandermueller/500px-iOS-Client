//
//  UIScrollView+ScrollToView.swift
//  500pxApiChallenge
//
//  Created by Alexander Mueller on 2020-07-23.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import Foundation
import UIKit

// This code was taken (and modified) from AMAN77's post on Stackoverflow:
// https://stackoverflow.com/questions/39018017/programmatically-scroll-a-uiscrollview-to-the-top-of-a-child-uiview-subview-in

extension UIScrollView {
    /* scrollToView:view:animated:
     * - Scrolls to the target view's y-position in the UIScrollView.
     *   Attempts to get the view as close to the top of the UIScrollView as
     *   possible given the content bounds of the UIScrollView.
     */
    func scrollToView(_ view: UIView?, animated: Bool) {
        guard let targetView = view else {
            return
        }
        
        if let origin = targetView.superview {
            // Get the Y position of your child view
            let childStartPoint = origin.convert(targetView.frame.origin, to: self)
            // Scroll to a rectangle starting at the Y of your subview, with a height of the scrollview
            self.scrollRectToVisible(CGRect(x: 0, y: childStartPoint.y, width: 1, height: self.frame.height), animated: animated)
        }
    }
}
