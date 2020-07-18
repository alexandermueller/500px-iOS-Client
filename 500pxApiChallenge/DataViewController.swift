//
//  DataViewController.swift
//  500pxApiChallenge
//
//  Created by Alex Mueller on 2020-07-17.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import UIKit

class DataViewController: UIViewController {
    @IBOutlet weak var dataLabel: UILabel!
    
    var dataTitle: String = ""
    var images: [Image] = []
    
    func updateViewWith(dataTitle: String, images: [Image]) {
        self.dataTitle = dataTitle
        self.images = images
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
}

