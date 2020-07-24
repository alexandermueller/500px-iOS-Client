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
let kMinImageScaleValue = 0
let kMaxImageScaleValue = 2
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
// MARK: - UI Variables
    
    @IBOutlet weak var pageLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var pageNumber: Int = 1
    private var pageTitle: String = "" {
        didSet {
            pageLabel?.text = pageTitle
        }
    }
    private var pageFeature: String = ""
    private var pageCount: Int = 0 {
        didSet {
            pageTitle = "\(pageFeature.capitalized) Images - Page \(pageNumber)/\(pageCount)"
        }
    }
    private var columns: Int {
        return (pow(2.0, currentImageScale) as NSNumber).intValue
    }
    private var cellWidth: Double {
        return Double(scrollView.frame.width) / Double(columns)
    }
    private var imageWidth: Double {
        return Double(cellWidth) - kCellMargin * 2
    }
    
// MARK: - Scale Variables
    
    private var currentImageScale = kMaxImageScaleValue {
        didSet {
            currentImageScale = max(kMinImageScaleValue, min(currentImageScale, kMaxImageScaleValue))
            
            if oldValue != currentImageScale {
                redrawScrollView()
            }
        }
    }
    private var lastPinchScale: CGFloat = 0.0
    private var lastPinchVelocity: CGFloat = 0.0
    
// MARK: - Image Variables
    
    private var imageButtons: [UIButton] = []
    private var imageInfoViews: [ImageInfoView] = []
    private var pageDataSubject = BehaviorSubject<PageData>(value: .defaultPageData())
    private var bag = DisposeBag()
    
// MARK: - Setup And ViewController Methods
    
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
        currentImageScale = kMaxImageScaleValue
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
        
        imageButtons = []
        imageInfoViews = []
        
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
            imageButton.addTarget(self, action: #selector(buttonTouchUpInside), for: UIControl.Event.touchUpInside)
            
            var lowestSize: Int = 0
            var largestSize: Int = .max
            var lowestSizeURL = ""
            var largestSizeURL = ""
            
            for image in imageInfo.images {
                if lowestSize < image.size {
                    lowestSize = image.size
                    lowestSizeURL = image.httpsUrl
                }
                
                if largestSize > image.size {
                    largestSize = image.size
                    largestSizeURL = image.httpsUrl
                }
            }
            
            imageButton.load(lowestSizeURL: URL(string: lowestSizeURL), largestSizeURL: URL(string: largestSizeURL))
            
            let imageInfoView = ImageInfoView.loadViewFromNib()
            imageInfoView.titleLabel.text = imageInfo.name
            imageInfoView.usernameLabel.text = "\(imageInfo.user.username) (\(imageInfo.user.fullname))"
            imageInfoView.viewsLabel.text = imageInfo.timesViewed.toShortString()
            imageInfoView.positiveRanksLabel.text = imageInfo.positiveVotesCount.toShortString()
            imageInfoView.commentsLabel.text = imageInfo.commentsCount.toShortString()
            imageInfoView.descriptionTextView.text = imageInfo.description.isEmpty ? "No Description" : imageInfo.description
            imageInfoView.isHidden = true
            
            scrollView.addSubview(imageButton)
            
            imageButtons += [imageButton]
            imageInfoViews += [imageInfoView]
        }
        
        redrawScrollView()
    }
    
    func redrawScrollView() {
        for (index, imageButton) in imageButtons.enumerated() {
            let imageX = Double(index % columns) * cellWidth + kCellMargin
            var imageY = Double(index / columns) * cellWidth + kCellMargin
            var imageHeight = imageWidth
            
            // Draw image to the appropriate height according to the aspect ratio when colums == 1
            if columns == 1 {
                if index > 0 {
                    let lastImageInfoView = imageInfoViews[index - 1]
                    imageY = Double(lastImageInfoView.frame.origin.y + lastImageInfoView.frame.size.height) + kCellMargin * 2
                }
                
                for state in [UIControl.State.reserved, UIControl.State.normal] {
                    if let size = imageButton.image(for: state)?.size {
                        imageHeight = Double(size.height / size.width) * imageWidth
                        break
                    }
                }
            }
            
            let imageInfoView = imageInfoViews[index]
            let infoY = imageY + imageHeight
            let infoHeight: Double = Double(imageInfoView.frame.height)
            let infoWidth: Double = columns == 1 ? imageWidth : Double(scrollView.frame.width)
            imageInfoView.isHidden = currentImageScale != kMinImageScaleValue
            
            let contentHeight = infoY + infoHeight * (imageInfoView.isHidden ? 0 : 1) + kCellMargin
            scrollView.contentSize = CGSize(width: Double(scrollView.frame.width), height: contentHeight)
            
            imageButton.layoutIfNeeded()
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveLinear, animations: { [imageWidth] in
                imageButton.frame = CGRect(x: imageX, y: imageY, width: imageWidth, height: imageHeight)
                imageButton.layoutIfNeeded()
            }, completion: nil)
            
            if !imageInfoView.isHidden {
                scrollView.addSubviewIfNecessary(imageInfoView)
                imageInfoView.layoutIfNeeded()
                UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveLinear, animations: { [infoWidth] in
                    imageInfoView.frame = CGRect(x: imageX, y: infoY, width: infoWidth, height: infoHeight)
                    imageInfoView.layoutIfNeeded()
                }, completion: nil)
            } else {
                imageInfoView.removeFromSuperview()
            }
        }
    }

// MARK: - UIScrollView Delegate
    
    // TODO: implement rotating wheel for when user scrolls down far enough or when the view is empty.
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
    
// MARK: - UIButton Touch
    
    @objc func buttonTouchUpInside(sender: UIButton!) {
        currentImageScale = kMinImageScaleValue
        scrollView.scrollToView(view: sender, animated: true)
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
