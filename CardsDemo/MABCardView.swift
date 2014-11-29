//
//  MABCardView.swift
//  CardsForTwitter
//
//  Created by Muhammad Bassio on 11/27/14.
//  Copyright (c) 2014 Muhammad Bassio. All rights reserved.
//

import UIKit

class MABCardView: UIView {

  override init(frame: CGRect) {
    super.init(frame: frame)
    self.setup()
  }

  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.setup()
  }
  
  func setup() {
    self.backgroundColor = UIColor.whiteColor()
    var shadowColor2 = UIColor(red: 0.209, green: 0.209, blue: 0.209, alpha: 1)
    var shadow = shadowColor2.colorWithAlphaComponent(0.73)
    var shadowOffset = CGSizeMake(3.1/2.0, -0.1/2.0);
    var shadowBlurRadius = 6.0 as CGFloat
    self.layer.shadowColor = shadow.CGColor
    self.layer.shadowOpacity = 0.73
    self.layer.shadowOffset = shadowOffset
    self.layer.shadowRadius = shadowBlurRadius
    self.layer.shouldRasterize = true
    
    self.layer.cornerRadius = 10
    
    
  }
  
}
