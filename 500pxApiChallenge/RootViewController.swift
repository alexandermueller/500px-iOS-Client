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
 * - The root view controller, containing the root UIPageViewController.
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
        
        rootPageViewController!.view.frame = view.bounds
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
}

