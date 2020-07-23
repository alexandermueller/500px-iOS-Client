//
//  ModelController.swift
//  500pxApiChallenge
//
//  Created by Alex Mueller on 2020-07-17.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import UIKit
import RxSwift

/* ModelController:
 * - Manages a collection of 500px image pages found under one specified page feature.
 *   Creates, configures, and returns new view controllers on demand, only caching the
 *   page data retrieved from the 500px API.
 *
 *             apiManager: Handles all calls to the 500px API
 *              pageCount: The page count of the specified feature collection
 *            pageFeature: The specified page feature
 *          pageDataCache: A cache of PageData BehaviorSubjects that self-invalidates to ensure up-to-date content
 * rootPageViewController: A reference to the root UIPageViewController
 *                    bag: A DisposeBag that performs trash collection after RxSwift interactions lose scope
 */
class ModelController: NSObject, UIPageViewControllerDataSource {
    private let apiManager = APIManager()
    private var pageCount: Int = 1 {
        didSet {
            // Refresh the data source of the UIPageViewController whenever the pageCount changes.
            // This lets the user go past the initial page bounderies if they are no longer accurate.
            if let root = self.rootPageViewController {
                root.dataSource = nil
                root.dataSource = self
            }
        }
    }
    private var pageFeature: String = ""
    private var pageDataCache = ValidatedPageDataSubjectCache()
    private var rootPageViewController: UIPageViewController? = nil
    private let bag = DisposeBag()
    
    /* initializeModelFor:feature:with:rootPageViewController:
     * - Initializes the Model to have a given feature and reference to the root UIPageViewController.
     *   Triggers a request for the first page's data, updating the page count upon a successful response.
     */
    func initializeModelFor(feature: String, with rootPageViewController: UIPageViewController?) {
        pageFeature = feature
        self.rootPageViewController = rootPageViewController
        let pageDataSubject = fetchPageDataFor(index: 0)
        
        // TODO: This will only update pageCount once. Maybe move this into a better spot for continuous updates
        pageDataSubject.subscribe(onNext: { [weak self] pageData in
            DispatchQueue.main.async {
                self?.pageCount = pageData.totalPages
            }
        }).disposed(by: bag)
    }
    
    /* fetchPageDataFor:index:
     * - Either:
     *   • Returns a cached PageData subject if the page already exists in the cache and the data is still valid
     *   • Returns a re-validated PageData subject awaiting data from an API request if the page already exists
           in the cache but the data is invalid
     *   • Or returns a new PageData subject awaiting data from an API request and stores it in the cache
     */
    @discardableResult private func fetchPageDataFor(index: Int) -> BehaviorSubject<PageData> {
        if let pageDataSubject = pageDataCache.fetch(at: index) {
            return pageDataSubject
        }
        
        let pageDataSubject = apiManager.fetchPageDataFor(feature: pageFeature, page: index + 1, invalidPageDataSubject: pageDataCache.fetchEvenIfInvalid(at: index))
        pageDataCache.validateExistingOrSetNew(pageDataSubject, for: index)
        
        return pageDataSubject
    }
    
    /* getFirstViewController:storyboard:
     * - Called by the RootViewController during intial setup. Retrieves the first PageViewController
     *   (implicitly triggering a fetch request for that page's data), and triggers a pre-fetch request
     *   for the second page's data so it's ready once the user transitions to the next page.
     * - Returns the first PageViewController in the page collection
     */
    func getFirstViewController(_ storyboard: UIStoryboard) -> PageViewController? {
        let viewController = viewControllerAtIndex(0, storyboard: storyboard)
        fetchPageDataFor(index: 1) // Prefetch the next pageData
        return viewController
    }
    
    /* viewControllerAtIndex:index:storyboard:
     * - Returns and initializes the PageViewController at a given page index, triggering a fetch for
     *   that view's page data.
     */
    func viewControllerAtIndex(_ index: Int, storyboard: UIStoryboard) -> PageViewController? {
        // Return nil if the requested page's index is greater than the page count.
        if (index >= pageCount) {
            return nil
        }
        
        // Create a new view controller and pass suitable data.
        let pageViewController = storyboard.instantiateViewController(withIdentifier: "PageViewController") as! PageViewController
        pageViewController.initializeWith(feature: pageFeature, pageNumber: index + 1, pageCount: pageCount, pageDataSubject: fetchPageDataFor(index: index))
        
        return pageViewController
    }

    // MARK: - Page View Controller Data Source

    func pageViewController(_ rootPageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        var index = (viewController as! PageViewController).pageNumber - 1
        
        if index == 0 {
            return nil
        } else if index - 1 != 0 {
            fetchPageDataFor(index: index - 1) // Preload cache at the previous page if it's invalid already
        }
        
        index -= 1
        
        return viewControllerAtIndex(index, storyboard: viewController.storyboard!)
    }

    func pageViewController(_ rootPageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        var index = (viewController as! PageViewController).pageNumber - 1
        
        index += 1
        
        if index == pageCount {
            return nil
        } else if index != pageCount - 1 {
            fetchPageDataFor(index: index + 1) // Preload cache at the next page if it's invalid already
        }
        
        return viewControllerAtIndex(index, storyboard: viewController.storyboard!)
    }

}

