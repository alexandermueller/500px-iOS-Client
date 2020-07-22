//
//  RootViewController.swift
//  500pxApiChallenge
//
//  Created by Alex Mueller on 2020-07-17.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import UIKit

let kDefaultFeature = "popular"

/* RootViewController:
 * - The root view controller, containing the UIPageViewController.
 *   Automatically generated via Apple's application templates, modified
 *   slightly to improve readablility and conform to the modified project
 *   nomenclature.
 */
class RootViewController: UIViewController, UIPageViewControllerDelegate {
    var rootPageViewController: UIPageViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        // Configure the page view controller and add it as a child view controller.
        rootPageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        rootPageViewController!.delegate = self

        let startingViewController: PageViewController = modelController.getFirstViewController(storyboard!)!
        let viewControllers = [startingViewController]
        
        rootPageViewController!.setViewControllers(viewControllers, direction: .forward, animated: false, completion: {done in })
        rootPageViewController!.dataSource = modelController
        addChild(rootPageViewController!)
        view.addSubview(rootPageViewController!.view)

        // Set the page view controller's bounds using an inset rect so that self's view is visible around the edges of the pages.
        var pageViewRect = view.bounds
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            pageViewRect = pageViewRect.insetBy(dx: 40.0, dy: 40.0)
        }
        
        rootPageViewController!.view.frame = pageViewRect
        rootPageViewController!.didMove(toParent: self)
    }

    var modelController: ModelController {
        // Return the model controller object, creating it if necessary.
        // In more complex implementations, the model controller may be passed to the view controller.
        
        if _modelController == nil {
            _modelController = ModelController()
            _modelController?.initializeModelFor(feature: kDefaultFeature, with: rootPageViewController)
        }
        
        return _modelController!
    }

    var _modelController: ModelController? = nil

    // MARK: - UIPageViewController delegate methods

    func pageViewController(_ pageViewController: UIPageViewController, spineLocationFor orientation: UIInterfaceOrientation) -> UIPageViewController.SpineLocation {
        if (orientation == .portrait) || (orientation == .portraitUpsideDown) || (UIDevice.current.userInterfaceIdiom == .phone) {
            // In portrait orientation or on iPhone: Set the spine position to "min" and the page view controller's view controllers array to contain just one view controller. Setting the spine position to 'UIPageViewController.SpineLocation.mid' in landscape orientation sets the doubleSided property to true, so set it to false here.
            let currentViewController = rootPageViewController!.viewControllers![0]
            let viewControllers = [currentViewController]
            
            rootPageViewController!.setViewControllers(viewControllers, direction: .forward, animated: true, completion: {done in })
            rootPageViewController!.isDoubleSided = false
            return .min
        }

        // In landscape orientation: Set set the spine location to "mid" and the page view controller's view controllers array to contain two view controllers. If the current page is even, set it to contain the current and next view controllers; if it is odd, set the array to contain the previous and current view controllers.
        let currentViewController = rootPageViewController!.viewControllers![0] as! PageViewController
        var viewControllers: [UIViewController]
        let indexOfCurrentViewController = currentViewController.pageNumber - 1
        
        if (indexOfCurrentViewController == 0) || (indexOfCurrentViewController % 2 == 0) {
            let nextViewController = modelController.pageViewController(rootPageViewController!, viewControllerAfter: currentViewController)
            viewControllers = [currentViewController, nextViewController!]
        } else {
            let previousViewController = modelController.pageViewController(rootPageViewController!, viewControllerBefore: currentViewController)
            viewControllers = [previousViewController!, currentViewController]
        }
        
        rootPageViewController!.setViewControllers(viewControllers, direction: .forward, animated: true, completion: {done in })

        return .mid
    }
}

