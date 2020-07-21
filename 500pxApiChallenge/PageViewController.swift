//
//  PageViewController.swift
//  500pxApiChallenge
//
//  Created by Alex Mueller on 2020-07-17.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import UIKit
import RxSwift

let kMinZoomLevel = 1
let kMaxZoomLevel = 3
let kImageColumns = 4

/* PageViewController:
 * - The view controller for each individual page in the UIPageView.
 *   Initializes and displays the Image previews passed through the corresponding
 *   PageData subject on a grid in the page's view.
 *
 *       pageLabel: An outlet to the view's page label
 *      pageNumber: The page number as it appears in the feature page collection via the 500px API
 *       dataTitle: The title of the page view
 * pageDataSubject: The data source for the page view controoller
 *             bag: A DisposeBag that performs trash collection after RxSwift interactions lose scope
 */
class PageViewController: UIViewController, UIScrollViewDelegate {
    @IBOutlet weak var pageContentView: UIView!
    @IBOutlet weak var pageLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var pageNumber: Int = 1
    private var dataTitle: String = ""
    private var imageDataDict: [String : ImageData] = [:]
    private var imageButtons: [UIButton] = []
    private var pageDataSubject = BehaviorSubject<PageData>(value: .defaultPageData())
    private var cellWidth: Int {
        return Int(pageContentView.frame.width) / kImageColumns
    }
    private var cellMargin: Int {
        return 1
    }
    private var imageWidth: Int {
        return cellWidth - cellMargin * 2
    }
    
    private var bag = DisposeBag()
    
    /* initializeWith:feature:pageNumber:pageCount:pageDataSubject:
     * - Sets up the view controller with the corresponding feature, page number, page count, and PageData subject.
     *   Subscribes to the PageData subject, which triggers an image view update whenever the PageData is refreshed.
     */
    func initializeWith(feature: String, pageNumber: Int, pageCount: Int, pageDataSubject: BehaviorSubject<PageData>) {
        self.pageNumber = pageNumber
        self.dataTitle = "\(feature.capitalized) Images Page \(pageNumber)/\(pageCount)"
        self.pageDataSubject = pageDataSubject
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        
        self.pageDataSubject.subscribe(onNext: { [weak self] pageData in
            DispatchQueue.main.async {
                self?.updateImageViews(with: pageData.photos)
            }
        }).disposed(by: bag)
        
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        pageLabel.text = dataTitle
        redrawScrollView()
    }
    
    /* updateImageViews:with:imageData:
     * - Refreshes the image views on the page to reflect the given ImageData array.
     */
    func updateImageViews(with imageData: [ImageData]) {
        assert(Thread.isMainThread, "Changes to UI have to be made on main thread!")
        
        imageDataDict = [:]
        imageButtons = []
        
        for subview in scrollView.subviews {
            subview.removeFromSuperview()
        }
                
        for image in imageData {
            let imageKey = "\(image.name) by \(image.user.fullname)"
            
            imageDataDict[imageKey] = image
            
            let imageButton = UIButton()
            imageButton.backgroundColor = .black
            imageButton.setTitle(imageKey, for: .reserved)
            imageButton.showsTouchWhenHighlighted = true
            
            if let lowestQuality = image.images.first {
                imageButton.load(linkURL: URL(string: lowestQuality.httpsUrl))
            }
            
            imageButton.addTarget(self, action: #selector(buttonTouchDown), for: UIControl.Event.touchDown)
            imageButton.addTarget(self, action: #selector(buttonTouchUpInside), for: UIControl.Event.touchUpInside)
            imageButton.addTarget(self, action: #selector(buttonTouchUpOutside), for: UIControl.Event.touchUpOutside)

            scrollView.addSubview(imageButton)            
            imageButtons += [imageButton]
        }
        
        redrawScrollView()
    }
    
    func redrawScrollView() {
        for (index, imageButton) in imageButtons.enumerated() {
            let imageY = (index / kImageColumns) * cellWidth + cellMargin
            let imageX = (index % kImageColumns) * cellWidth + cellMargin
            
            imageButton.frame = CGRect(x: imageX, y: imageY, width: imageWidth, height: imageWidth)
            scrollView.contentSize = CGSize(width: Int(pageContentView.frame.width), height: imageY + imageWidth + cellMargin)
        }
    }
    
    @objc func buttonTouchDown(sender: UIButton!) {
        sender.isHighlighted = true
        sender.backgroundColor = .lightGray
    }
    
    @objc func buttonTouchUpInside(sender: UIButton!) {
        sender.isHighlighted = false
        sender.backgroundColor = .black
    }
    
    @objc func buttonTouchUpOutside(sender: UIButton!) {
        sender.isHighlighted = false
        sender.backgroundColor = .black
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        for imageButton in imageButtons {
            imageButton.isHighlighted = false
            imageButton.backgroundColor = .black
        }
    }
    
    @objc func rotated() {
        redrawScrollView()
    }
    
    deinit {
       NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
}

