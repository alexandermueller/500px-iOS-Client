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
let kMinDrawingScale = 0
let kMaxDrawingScale = 2
let kImageScaleThresholdValue = 3
let kCellMargin = 1.0

/* PageViewController:
 * - The view controller for each individual page in the UIPageView.
 *   Initializes and displays the Image previews passed through the corresponding
 *   PageData subject on a grid in the page's UIScrollView. Supports pinching of
 *   the UIScrollView to rescale the images displayed in the grid from
 *   4 <-> 2 <-> 1 column(s) spanning the width of the UIScrollView.
 *
 * - UI Variables:
 *           pageLabel: An outlet to the view's page label
 *          scrollView: A scrollable view that contains/displays the images on a grid
 *          pageNumber: The page number as it appears in the feature page collection via the 500px API
 *           pageTitle: The title string of the page. Triggers an update to the pageLabel when set.
 *         pageFeature: The feature type of the page.
 *           pageCount: The total pages in the current image feature set. Triggers an update to the pageTitle when set.
 *             columns: Calculates the number of columns being displayed on the grid according to the drawing scale, i.e.
*                       the larger the drawing scale, the fewer columns, meaning the larger the images are drawn.
 *           cellWidth: Calculates the width of a single cell in the grid according to the current number of columns
 *          imageWidth: Calculates the width of a single image inside a cell given the cell margin size.
 * lastScrollViewFrame: The last recent scrollView frame, updated when ViewDidLoad or ViewDidLayoutSubviews occurs.
 *                      primarily used to ensure that any redraws made in ViewDidLayoutSubviews occur only if the frame size changes,
 *                      preventing any unnecessary redraws as ViewDidLayoutSubviews gets called a lot.
 *                      ie: after a rotation of the device, after a page transition, etc.
 *
 * - Scale Variables:
 *        drawingScale: Keeps track of the drawing scale in the scrollView. Increase in drawingScale translates to fewer image columns in
 *                      the scrollView -> larger images, and vice versa.
 *      lastPinchScale: Keeps track of the last pinch "scale" value returned from the UIPinchGestureRecognizer attached to the scrollView.
 *   lastPinchVelocity: Keeps track of the last pinch "velocity" value returned from the UIPinchGestureRecognizer attached to the scrollView.
 *
 * - ImageVariables:
 *  firstVisibleButton: Keeps track of the first visible image in the scrollView (from the top-left corner.)
 *        imageButtons: An array containing all the buttons are currently subviews in the scrollView.
 *      imageInfoViews: An array containing all the image data views, where an imageInfoView at index i corresponds to an imageButton at index i.
 *     pageDataSubject: The page data source for the current view controller
 *                 bag: A DisposeBag that performs trash collection after RxSwift interactions lose scope
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
        return (pow(2.0, kMaxDrawingScale - drawingScale) as NSNumber).intValue
    }
    private var cellWidth: Double {
        return Double(scrollView.frame.width) / Double(columns)
    }
    private var imageWidth: Double {
        return Double(cellWidth) - kCellMargin * 2
    }
    private var lastScrollViewFrame: CGRect? = nil
    
// MARK: - Scale Variables
    
    private var drawingScale = kMaxDrawingScale {
        didSet {
            drawingScale = max(kMinDrawingScale, min(drawingScale, kMaxDrawingScale))
            
            if oldValue != drawingScale {
                redrawScrollView()
            }
        }
    }
    private var lastPinchScale: CGFloat = 0.0
    private var lastPinchVelocity: CGFloat = 0.0
    
// MARK: - Image Variables
    
    private var firstVisibleButton: UIView? = nil
    private var imageButtons: [UIButton] = []
    private var imageInfoViews: [ImageInfoView] = []
    private var pageDataSubject = BehaviorSubject<PageData>(value: .defaultPageData())
    private var bag = DisposeBag()
    
// MARK: - Setup And ViewController Methods
    
    /* initializeWith:feature:pageNumber:pageCount:pageDataSubject:
     * - Sets up the view controller with the corresponding feature, page number, page count, and PageData subject.
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
        lastScrollViewFrame = scrollView.frame
        
        // Trigger a page count update and image view update whenever the PageData gets updated
        self.pageDataSubject.subscribe(onNext: { [weak self] pageData in
            DispatchQueue.main.async {
                self?.pageCount = pageData.totalPages
                self?.updateImageViews(with: pageData.photos)
            }
        }).disposed(by: bag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        drawingScale = kMinDrawingScale
    }
    
    override func viewDidLayoutSubviews() {
        // If the size of the scrollView frame changes after viewDidLayoutSubviews, redraw the images within
        // Primarily for when the device rotates, it will trigger a redraw and scroll to the first visible button
        // before the layout happened.
        if let frame = lastScrollViewFrame, frame != scrollView.frame {
            redrawScrollView()
            lastScrollViewFrame = scrollView.frame
            scrollView.scrollToView(firstVisibleButton, animated: false)
        }
    }
    
// MARK: - Image Drawing Methods
    
    /* updateImageViews:with:imageData:
     * - Clears the scrollView and generates a new imageButton and imageView for each image in the provided ImageData array.
     */
    private func updateImageViews(with imageDataArray: [ImageData]) {
        assert(Thread.isMainThread, "Changes to UI have to be made on main thread!")
        
        imageButtons = []
        imageInfoViews = []
        
        for subview in scrollView.subviews {
            subview.removeFromSuperview()
        }
                
        for imageInfo in imageDataArray {
            // Filter out any images that are missing links
            guard imageInfo.images.count > 0 else {
                continue
            }
            
            let imageButton = UIButton()
            imageButton.backgroundColor = .black
            imageButton.imageView?.contentMode = .scaleAspectFill
            imageButton.animatesPressActions(true)
            imageButton.addTarget(self, action: #selector(buttonTouchUpInside), for: UIControl.Event.touchUpInside)
            
            // Iterate the image's array of image urls to find the largest and smallest sized image urls
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
            
            // TODO: Implement solution to add large image to button
            imageButton.load(imageURL: URL(string: lowestSizeURL))
            
            let imageInfoView = ImageInfoView.loadViewFromNib()
            imageInfoView.titleLabel.text = imageInfo.name
            imageInfoView.usernameLabel.text = "\(imageInfo.user.username) (\(imageInfo.user.fullname))"
            imageInfoView.viewsLabel.text = imageInfo.timesViewed.shortForm()
            imageInfoView.positiveRanksLabel.text = imageInfo.positiveVotesCount.shortForm()
            imageInfoView.commentsLabel.text = imageInfo.commentsCount.shortForm()
            imageInfoView.descriptionTextView.text = imageInfo.description.isEmpty ? "No Description" : imageInfo.description
            
            scrollView.addSubview(imageButton)
            
            imageButtons += [imageButton]
            imageInfoViews += [imageInfoView]
        }
        
        // Trigger a redraw of the scrollView to display the new images
        redrawScrollView(animated: true)
    }
    
    /* redrawScrollView:animated:
     * - Redraws the scrollView to reflect changes in drawing scale, image data, orientation, etc.
     *   Lays out each image as an imageButton in the scrollView within a grid of images,
     *   scaled according to the drawing scale and scrollView frame width. If the scale is such
     *   that there is only one column on the screen, the images (imageButtons) are drawn with the
     *   corresponding info (imageInfoViews) beneath them. Otherwise, the info is removed from the
     *   scrollView.
     */
    private func redrawScrollView(animated: Bool = false) {
        for (index, imageButton) in imageButtons.enumerated() {
            let imageX = Double(index % columns) * cellWidth + kCellMargin
            var imageY = Double(index / columns) * cellWidth + kCellMargin
            var imageHeight = imageWidth
            
            // Draw image to the appropriate height according to the aspect ratio when colums == 1
            if columns == 1 {
                // Draw the current image under the last image's info view
                if index > 0 {
                    let lastImageInfoView = imageInfoViews[index - 1]
                    imageY = Double(lastImageInfoView.frame.origin.y + lastImageInfoView.frame.size.height) + kCellMargin * 2
                }
                
                // Grab the image's size and calculate the new height according to the image's original aspect ratio multiplied
                // by the imageWidth. If the calculated height > original height, use that instead, otherwise the image will have
                // black bars above and below it.
                if let size = imageButton.image(for: .normal)?.size {
                    imageHeight = min(Double(size.height / size.width) * imageWidth, Double(size.height))
                }
            }
            
            let imageInfoView = imageInfoViews[index]
            let infoY = imageY + imageHeight
            let infoHeight: Double = Double(imageInfoView.frame.height)
            let infoWidth: Double = columns == 1 ? imageWidth : Double(scrollView.frame.width)
            
            // Update the scrollView's content height to match the new image and info view's heights
            let contentHeight = infoY + infoHeight * (columns == 1 ? 1 : 0) + kCellMargin
            scrollView.contentSize = CGSize(width: Double(scrollView.frame.width), height: contentHeight)
            
            imageButton.layoutIfNeeded()
            imageInfoView.layoutIfNeeded()
            
            var drawingViews: [(UIView, CGRect)] = [(imageButton, CGRect(x: imageX, y: imageY, width: imageWidth, height: imageHeight))]
            
            // Add/remove imageInfoViews from the scrollView depending on if they should be drawn.
            // This really helps keep the app feeling snappy and responsive
            if columns == 1 {
                scrollView.addSubviewIfNecessary(imageInfoView)
                drawingViews += [(imageInfoView, CGRect(x: imageX, y: infoY, width: infoWidth, height: infoHeight))]
            } else {
                imageInfoView.removeFromSuperview()
            }
            
            // Draw all views that need to be drawn for the current imageButton, animating the change if needed.
            for (drawingView, drawingRect) in drawingViews {
                let drawingBlock = {
                    drawingView.frame = drawingRect
                    drawingView.layoutIfNeeded()
                }
                
                if animated {
                    UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveLinear, animations: drawingBlock, completion: nil)
                    continue
                }
                
                drawingBlock()
            }
        }
    }
    
// MARK: - UIScrollView Delegate
    
    /* firstVisibleButtonInScrollView:
     * - Iterates imageButtons and returns the first imageButton that intersects with the scrollView's bounds.
     *   Essentially, returning the first visible imageButton in the scrollView (always the top-left-most image
     *   currently displayed.)
     */
    private func firstVisibleButtonInScrollView() -> UIButton? {
        for button in imageButtons {
            if scrollView.bounds.intersects(button.frame) {
                return button
            }
        }
        
        return nil
    }
    
    // Due to an iPad bug, scrollViewDidScroll is triggered whenever the device orientation changes,
    // so as a workaround, we have to listen to scrollViewDidEndDragging and scrollViewDidEndDecelerating
    // instead to update the firstVisibleButton. Otherwise, iPad orientation changes would default the
    // firstVisibleButton to equal the first imageButton in imageButtons.
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            firstVisibleButton = firstVisibleButtonInScrollView()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        firstVisibleButton = firstVisibleButtonInScrollView()
    }
    
// MARK: - UIButton Touch
    
    // Whenever the user finishes a touch inside the imageButton, maximize the drawing scale
    // (triggering a redraw), and scroll to and set the firstVisibleButton to the tapped imageButton.
    
    @objc private func buttonTouchUpInside(sender: UIButton!) {
        let previousDrawingScale = drawingScale
        drawingScale = kMaxDrawingScale
        scrollView.scrollToView(sender, animated: previousDrawingScale == kMaxDrawingScale)
        firstVisibleButton = sender
    }
    
// MARK: - UIPinchGestureRecognizer
    
    // Maps pinch gestures on the scrollView to change the drawing scale of the images displayed
    // inside the scrollView.
    
    @IBAction private func didPinch(_ sender: UIPinchGestureRecognizer) {
        let pinchVelocity: CGFloat = sender.velocity
        let pinchScale: CGFloat = sender.scale
    
        switch sender.state {
        case .began:
            lastPinchScale = pinchScale
            lastPinchVelocity = pinchVelocity
        case .changed:
            // Reset pinch scale if velocity changes, ie, when a pinch in becomes a pinch out.
            if pinchVelocity > 0 && lastPinchVelocity < 0 || pinchVelocity < 0 && lastPinchVelocity > 0 {
                lastPinchScale = pinchScale
            }
                    
            // Change image drawing scale if the pinch scale difference goes past the image scale threshold value,
            // ie, pinching inwards increases the drawn columns on the screen, lowering the drawn scale of the
            // images displayed and vice versa.
            if abs(lastPinchScale - pinchScale) * 10 > CGFloat(kImageScaleThresholdValue) {
                drawingScale += (pinchVelocity > 0 ? 1 : -1)
                scrollView.scrollToView(firstVisibleButton, animated: false)
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
