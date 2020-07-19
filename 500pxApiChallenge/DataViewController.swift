//
//  DataViewController.swift
//  500pxApiChallenge
//
//  Created by Alex Mueller on 2020-07-17.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import UIKit
import RxSwift

class DataViewController: UIViewController {
    @IBOutlet weak var dataLabel: UILabel!
    
    var pageNumber: Int = 1
    var imagesSubject = BehaviorSubject<[Image]>(value: [])
    var dataTitle: String = ""
    var images: [Image] = [] {
        didSet {
            DispatchQueue.main.async {
                self.updateImagesView()
            }
        }
    }
    var bag = DisposeBag()
    
    func updateViewWith(feature: String, pageNumber: Int, imagesSubject: BehaviorSubject<[Image]>) {
        self.pageNumber = pageNumber
        self.dataTitle = "\(feature.capitalized) Images Page \(pageNumber)"
        self.imagesSubject = imagesSubject
        
        imagesSubject.subscribe(onNext: { [weak self] images in
            self?.images = images
        }).disposed(by: bag)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // ie, this is where we will grab the images.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.dataLabel!.text = dataTitle
    }
    
    func updateImagesView() {
        
    }
}

