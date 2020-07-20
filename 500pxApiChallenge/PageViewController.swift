//
//  PageViewController.swift
//  500pxApiChallenge
//
//  Created by Alex Mueller on 2020-07-17.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import UIKit
import RxSwift

/* PageViewController:
 * - The view controller for each individual page in the UIPageView.
 *   Initializes and displays the Image previews passed through the corresponding
 *   PageData subject on a grid in the page's view.
 *
 *       pageLabel: An outlet to the view's page label
 *      pageNumber: The page number as it appears in the feature page collection via the 500px API
 * pageDataSubject: The data source for the page view controoller
 *       dataTitle: The title of the page view
 *             bag: A DisposeBag that performs trash collection after RxSwift interactions lose scope
 */
class PageViewController: UIViewController {
    @IBOutlet weak var pageLabel: UILabel!
    
    var pageNumber: Int = 1
    var pageDataSubject = BehaviorSubject<PageData>(value: .defaultPageData())
    var dataTitle: String = ""
    var bag = DisposeBag()
    
    /* updateViewWith:feature:pageNumber:pageDataSubject:
     * - Sets up the view controller with the corresponding feature, page number, and PageData subject.
     *   Subscribes to the PageData subject, which triggers an image view update whenever the PageData is
     *   refreshed.
     */
    func updateViewWith(feature: String, pageNumber: Int, pageDataSubject: BehaviorSubject<PageData>) {
        self.pageNumber = pageNumber
        self.dataTitle = "\(feature.capitalized) Images Page \(pageNumber)"
        self.pageDataSubject = pageDataSubject
        
        pageDataSubject.subscribe(onNext: { [weak self] pageData in
            DispatchQueue.main.async {
                self?.updateImageViews(with: pageData.photos)
            }
        }).disposed(by: bag)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // ie, this is where we will grab the images.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.pageLabel!.text = dataTitle
    }

    /* updateImageViews:with:imageData:
     * - Refreshes the image views on the page to reflect the given ImageData array.
     */
    func updateImageViews(with imageData: [ImageData]) {
        
    }
}

