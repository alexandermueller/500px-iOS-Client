//
//  ImageInfoView.swift
//  500pxApiChallenge
//
//  Created by Alexander Mueller on 2020-07-24.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import UIKit

class ImageInfoView: UIView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var viewsLabel: UILabel!
    @IBOutlet weak var positiveRanksLabel: UILabel!
    @IBOutlet weak var commentsLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!

    class func loadViewFromNib() -> ImageInfoView {
        return UINib(nibName: "ImageInfoView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! ImageInfoView
    }
}
