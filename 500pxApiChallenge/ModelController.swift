//
//  ModelController.swift
//  500pxApiChallenge
//
//  Created by Alex Mueller on 2020-07-17.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import UIKit

/*
 A controller object that manages a simple model -- a collection of month names.
 
 The controller serves as the data source for the page view controller; it therefore implements pageViewController:viewControllerBeforeViewController: and pageViewController:viewControllerAfterViewController:.
 It also implements a custom method, viewControllerAtIndex: which is useful in the implementation of the data source methods, and in the initial configuration of the application.
 
 There is no need to actually create view controllers for each page in advance -- indeed doing so incurs unnecessary overhead. Given the data model, these methods create, configure, and return a new view controller on demand.
 */

class ModelController: NSObject, UIPageViewControllerDataSource {

    // TODO: make ScreenZoom variable react to pinches so it keeps track of the screen zoom level (1, 2, 3, ...)
    var zoomLevel: Int = 1 {
        didSet {
            zoomLevel = max(kMaxZoomLevel, min(zoomLevel, kMinZoomLevel))
            self.refreshPageData()
        }
    }
    
    var pageData: [String] = []
    var images: [UIImage]
    
    override init() {
        images = []
        
        super.init()
        refreshPageData()
    }

    // Eventually this will update every view to reflect the zoom level? We shall see...
    func refreshPageData() {
        pageData = Array(1...100).map({ "Popular Images Page \($0)" })
    }
    
    func viewControllerAtIndex(_ index: Int, storyboard: UIStoryboard) -> DataViewController? {
        // Return the data view controller for the given index.
        if (self.pageData.count == 0) || (index >= self.pageData.count) {
            return nil
        }

        // Create a new view controller and pass suitable data.
        let dataViewController = storyboard.instantiateViewController(withIdentifier: "DataViewController") as! DataViewController
        dataViewController.updateViewWith(dataTitle: pageData[index], images: [])
        
        return dataViewController
    }

    func indexOfViewController(_ viewController: DataViewController) -> Int {
        // Return the index of the given data view controller.
        // For simplicity, this implementation uses a static array of model objects and the view controller stores the model object; you can therefore use the model object to identify the index.
        return pageData.firstIndex(of: viewController.dataTitle) ?? NSNotFound
    }

    // MARK: - Page View Controller Data Source

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        var index = self.indexOfViewController(viewController as! DataViewController)
        if (index == 0) || (index == NSNotFound) {
            return nil
        }
        
        index -= 1
        
        return self.viewControllerAtIndex(index, storyboard: viewController.storyboard!)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        var index = self.indexOfViewController(viewController as! DataViewController)
        if index == NSNotFound {
            return nil
        }
        
        index += 1
        
        if index == self.pageData.count {
            return nil
        }
        
        return self.viewControllerAtIndex(index, storyboard: viewController.storyboard!)
    }

}

