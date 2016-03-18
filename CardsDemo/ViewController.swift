//
//  ViewController.swift
//  CardsDemo
//
//  Created by Muhammad Bassio on 11/29/14.
//  Copyright (c) 2014 Muhammad Bassio. All rights reserved.
//

import UIKit

class ViewController: UIViewController, MABCardsContainerDelegate, MABCardsContainerDataSource {

  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  var swipeableView:MABCardsContainer!
  var colorIndex = 0
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = UIColor(red: 0, green: 176.0/255, blue: 1, alpha: 1)
    
    self.swipeableView = MABCardsContainer(frame: CGRectMake(20, 30, 280, 400))
    self.swipeableView.setNeedsLayout()
    self.swipeableView.layoutIfNeeded()
    self.swipeableView.dataSource = self;
    self.swipeableView.delegate = self;
    
    let btn = UIButton(frame: CGRectMake(10, 430, 300, 50))
    btn .setTitle("Reload Cards", forState: UIControlState.Normal)
    //btn.backgroundColor = UIColor.blackColor()
    btn.addTarget(self, action: "reload", forControlEvents: UIControlEvents.TouchUpInside)
    
    self.view.addSubview(swipeableView)
    self.view.addSubview(btn)
    
    self.reload()
    
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


  func reload() {
    self.colorIndex = 0
    self.swipeableView.discardAllSwipeableViews()
    self.swipeableView.loadNextSwipeableViewsIfNeeded(true)
  }
  
  
  func generateColor() -> UIColor {
    let randomRed:CGFloat = CGFloat(drand48())
    let randomGreen:CGFloat = CGFloat(drand48())
    let randomBlue:CGFloat = CGFloat(drand48())
    return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: 1.0)
  }
  
  
  // MABCardsContainerDelegate
  func containerViewDidSwipeLeft(containerView:MABCardsContainer, _: UIView) {}
  func containerViewDidSwipeRight(containerView:MABCardsContainer, _: UIView) {}
  func containerViewDidStartSwipingCard(containerView:MABCardsContainer, card:UIView, location:CGPoint) {}
  func containerSwipingCard(containerView:MABCardsContainer, card:UIView, location:CGPoint, translation:CGPoint) {}
  func containerViewDidEndSwipingCard(containerView:MABCardsContainer, card:UIView, location:CGPoint) {}
  
  // MABCardsContainerDataSource
  func nextCardViewForContainerView(containerView:MABCardsContainer) -> UIView! {
    if (self.colorIndex < 10) {
      let card = MABCardView(frame: swipeableView.bounds)
      card.backgroundColor = self.generateColor()
      self.colorIndex++;
      return card;
    }
    return nil;
  }
  
}

