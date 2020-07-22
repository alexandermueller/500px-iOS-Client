//
//  PageViewController.swift
//  500pxApiChallenge
//
//  Created by Alex Mueller on 2020-07-17.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import UIKit
import RxSwift

let kMaxImageColumns = 4
let kMinImageScale = 0
let kMaxImageScale = 2
let kImageScaleThresholdValue = 3
let kCellMargin = 1.0

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
    @IBOutlet weak var pageLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var pageNumber: Int = 1
    // TODO: Make a subject passed via dependancy injection that every view can update,
    //       Making the change happen globally?.
    private var currentImageScale = kMaxImageScale {
        didSet {
            currentImageScale = max(kMinImageScale, min(currentImageScale, kMaxImageScale))
            
            if oldValue != currentImageScale {
                redrawScrollView()
            }
        }
    }
    private var lastPinchScale: CGFloat = 0.0
    private var lastPinchVelocity: CGFloat = 0.0
    private var dataTitle: String = "" {
        didSet {
            pageLabel?.text = dataTitle
        }
    }
    private var pageFeature: String = ""
    private var pageCount: Int = 0 {
        didSet {
            dataTitle = "\(pageFeature.capitalized) Images - Page \(pageNumber)/\(pageCount)"
        }
    }
    private var imageDataArray: [ImageData] = []
    private var imageButtons: [UIButton] = []
    private var pageDataSubject = BehaviorSubject<PageData>(value: .defaultPageData())
    private var columns: Int {
        return (pow(2.0, currentImageScale) as NSNumber).intValue
    }
    private var cellWidth: Double {
        return Double(scrollView.frame.width) / Double(columns)
    }
    private var imageWidth: Double {
        return Double(cellWidth) - kCellMargin * 2
    }
    
    private var bag = DisposeBag()
    
    /* initializeWith:feature:pageNumber:pageCount:pageDataSubject:
     * - Sets up the view controller with the corresponding feature, page number, page count, and PageData subject.
     *   Subscribes to the PageData subject, which triggers an image view update whenever the PageData is refreshed.
     */
    func initializeWith(feature: String, pageNumber: Int, pageCount: Int, pageDataSubject: BehaviorSubject<PageData>) {
        self.pageNumber = pageNumber
        self.pageFeature = feature
        self.pageCount = pageCount
        self.pageDataSubject = pageDataSubject
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.delegate = self
        
        self.pageDataSubject.subscribe(onNext: { [weak self] pageData in
            DispatchQueue.main.async {
                self?.pageCount = pageData.totalPages
                self?.updateImageViews(with: pageData.photos)
            }
        }).disposed(by: bag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        pageLabel.text = dataTitle
        currentImageScale = kMaxImageScale // TODO: Figure out how and what the scale should be at
        redrawScrollView()
    }
    
    override func viewDidLayoutSubviews() {
       redrawScrollView()
    }
    
// MARK: - Image Drawing Methods
    
    /* updateImageViews:with:imageData:
     * - Refreshes the image views on the page to reflect the given ImageData array.
     */
    func updateImageViews(with imageDataArray: [ImageData]) {
        assert(Thread.isMainThread, "Changes to UI have to be made on main thread!")
        
        self.imageDataArray = []
        imageButtons = []
        
        for subview in scrollView.subviews {
            subview.removeFromSuperview()
        }
                
        for imageInfo in imageDataArray {
            guard imageInfo.images.count > 0 else {
                continue
            }
            
            let imageButton = UIButton()
            imageButton.backgroundColor = .black
            imageButton.imageView?.contentMode = .scaleAspectFill
            imageButton.animatesPressActions(true)
            
            var lowestSize: Int = .max
            var largestSize = 0
            var lowestSizeURL = ""
            var largestSizeURL = ""
            
            for image in imageInfo.images {
                if lowestSize > image.size {
                    lowestSize = image.size
                    lowestSizeURL = image.httpsUrl
                }
                
                if largestSize < image.size {
                    largestSize = image.size
                    largestSizeURL = image.httpsUrl
                }
            }
            
            imageButton.load(lowestSizeURL: URL(string: lowestSizeURL), largestSizeURL: URL(string: largestSizeURL))
            
            scrollView.addSubview(imageButton)
            imageButtons += [imageButton]
            self.imageDataArray += [imageInfo]
        }
        
        redrawScrollView()
    }
    
    func redrawScrollView() {
        for (index, imageButton) in imageButtons.enumerated() {
            var imageY = Double(index / columns) * cellWidth + kCellMargin
            let imageX = Double(index % columns) * cellWidth + kCellMargin
            var imageHeight = imageWidth

            // Draw image to the appropriate height according to the aspect ratio when colums == 1
            if columns == 1 {
                if index > 0 {
                    let lastImageButton = imageButtons[index - 1]
                    imageY = Double(lastImageButton.frame.origin.y + lastImageButton.frame.size.height) + kCellMargin * 2
                }
                
                if let size = imageButton.imageView?.image?.size {
                    imageHeight = Double(size.height / size.width) * imageWidth
                }
            }
            
            scrollView.contentSize = CGSize(width: Double(scrollView.frame.width), height: imageY + imageHeight + kCellMargin)
            
            imageButton.layoutIfNeeded()
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveLinear, animations: { [imageWidth] in
                imageButton.frame = CGRect(x: imageX, y: imageY, width: imageWidth, height: imageHeight)
                imageButton.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
// MARK: - UIScrollView Delegate
    
    // TODO: implement rotating wheel for when user scrolls down far enough or when the view is empty.
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
    }
    
// MARK: - UIPinchGestureRecognizer
    
    @IBAction func didPinch(_ sender: UIPinchGestureRecognizer) {
        let pinchVelocity: CGFloat = sender.velocity
        let pinchScale: CGFloat = sender.scale
        
        switch sender.state {
        case .began:
            lastPinchScale = pinchScale
            lastPinchVelocity = pinchVelocity
        case .changed:
            // Reset pinch scale if velocity changes
            if pinchVelocity > 0 && lastPinchVelocity < 0 || pinchVelocity < 0 && lastPinchVelocity > 0 {
                lastPinchScale = pinchScale
            }
                    
            // Change image scale if the difference goes past the image scale threshold value
            if abs(lastPinchScale - pinchScale) * 10 > CGFloat(kImageScaleThresholdValue) {
                currentImageScale += pinchVelocity < 0 ? 1 : -1
                lastPinchScale = pinchScale
            }
            
            lastPinchVelocity = pinchVelocity
        case .ended:
            lastPinchScale = 0.0
            lastPinchVelocity = 0.0
        default:
            break
        }
    }
}
