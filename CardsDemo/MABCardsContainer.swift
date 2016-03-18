//
//  MABCardsContainer.swift
//  CardsForTwitter
//
//  Created by Muhammad Bassio on 11/27/14.
//  Copyright (c) 2014 Muhammad Bassio. All rights reserved.
//

import UIKit

protocol MABCardsContainerDelegate {
  func containerViewDidSwipeLeft(containerView:MABCardsContainer, _: UIView)
  func containerViewDidSwipeRight(containerView:MABCardsContainer, _: UIView)
  func containerViewDidStartSwipingCard(containerView:MABCardsContainer, card:UIView, location:CGPoint)
  func containerSwipingCard(containerView:MABCardsContainer, card:UIView, location:CGPoint, translation:CGPoint)
  func containerViewDidEndSwipingCard(containerView:MABCardsContainer, card:UIView, location:CGPoint)
}

protocol MABCardsContainerDataSource {
  func nextCardViewForContainerView(containerView:MABCardsContainer) -> UIView!
}

class MABCardsContainer: UIView, UICollisionBehaviorDelegate, UIDynamicAnimatorDelegate {
  
  let numPrefetchedViews:NSInteger = 3
  
  var dataSource:MABCardsContainerDataSource! = nil
  var delegate:MABCardsContainerDelegate! = nil
  
  var isRotationEnabled:Bool = true
  var rotationDegree:CGFloat = 1
  var rotationRelativeYOffsetFromCenter:CGFloat = 0.3
  var escapeVelocityThreshold:CGFloat = 750
  var relativeDisplacementThreshold:CGFloat = 0.25
  var pushVelocityMagnitude:CGFloat = 1000
  
  var swipeableViewsCenter:CGPoint = CGPointMake(0, 0)
  var collisionRect:CGRect = CGRectMake(0, 0, 0, 0)
  
  var manualSwipeRotationRelativeYOffsetFromCenter:CGFloat = -0.2
  
  
  // UIDynamicAnimators
  private var animator:UIDynamicAnimator = UIDynamicAnimator()
  private var swipeableViewSnapBehavior:UISnapBehavior!
  private var swipeableViewAttachmentBehavior:UIAttachmentBehavior!
  private var anchorViewAttachmentBehavior:UIAttachmentBehavior!
  // AnchorView
  private var anchorContainerView:UIView = UIView()
  private var anchorView:UIView! = UIView()
  private var isAnchorViewVisiable:Bool = true

  private var reuseCoverContainerView:UIView = UIView()
  private var containerView:UIView = UIView()
  
  
  // Initialization Methods
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.setup()
  }
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.setup()
  }

  
  func setup() {
    
    self.animator = UIDynamicAnimator(referenceView: self)
    self.animator.delegate = self;
    self.anchorContainerView = UIView(frame: CGRectMake(0, 0, 1, 1))
    self.addSubview(self.anchorContainerView)
    self.isAnchorViewVisiable = false;
    self.containerView = UIView(frame: self.bounds)
    self.addSubview(self.containerView)
    self.reuseCoverContainerView = UIView(frame: self.bounds)
    self.reuseCoverContainerView.userInteractionEnabled = false;
    self.addSubview(self.reuseCoverContainerView)

    self.swipeableViewsCenter = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    self.collisionRect = self.defaultCollisionRect()
    
  }
  func defaultCollisionRect() -> CGRect {
    let viewSize = UIScreen.mainScreen().applicationFrame.size;
    let collisionSizeScale:CGFloat = 6.0;
    let collisionSize = CGSizeMake(viewSize.width * collisionSizeScale, viewSize.height * collisionSizeScale);
    let collisionRect = CGRectMake((-collisionSize.width / 2) + (viewSize.width / 2), (-collisionSize.height / 2) + (viewSize.height / 2), collisionSize.width, collisionSize.height);
    return collisionRect;
  }
  
  
  
  
  
  override func layoutSubviews() {
    super.layoutSubviews()
    self.anchorContainerView.frame = CGRectMake(0, 0, 1, 1);
    self.containerView.frame = self.bounds;
    self.reuseCoverContainerView.frame = self.bounds;
    self.swipeableViewsCenter = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
  }
  
  
  
  func discardAllSwipeableViews() {
    guard self.anchorViewAttachmentBehavior != nil else { return }
    self.animator.removeBehavior(self.anchorViewAttachmentBehavior)
    for view in self.containerView.subviews {
      view.removeFromSuperview()
    }
  }
  
  func loadNextSwipeableViewsIfNeeded(animated:Bool) {
    
    let numViews:NSInteger = self.containerView.subviews.count;
    let newViews:NSMutableArray = NSMutableArray();
    
    for var i = numViews; i < numPrefetchedViews; i++ {
      let nextView:UIView! = self.nextSwipeableView()
      if (nextView != nil) {
        self.containerView.addSubview(nextView)
        self.containerView.sendSubviewToBack(nextView)
        nextView.center = self.swipeableViewsCenter;
        newViews.addObject(nextView)
      }
    }
    
    if (animated) {
      let maxDelay:NSTimeInterval = 0.3
      let delayInNanoSec = dispatch_time(DISPATCH_TIME_NOW,Int64(maxDelay * Double(NSEC_PER_SEC)))
      let delayStep:NSTimeInterval = maxDelay / NSTimeInterval(numPrefetchedViews)
      var aggregatedDelay = maxDelay
      let animationDuration = 0.25
      for var j = 0; j < newViews.count; j++ {
        let view:UIView! = newViews[j] as! UIView
        view.center = CGPointMake(view.center.x, -view.frame.size.height);
        UIView.animateWithDuration(animationDuration, delay: aggregatedDelay, options: UIViewAnimationOptions.CurveEaseIn, animations: {
          view.center = self.swipeableViewsCenter
        }, completion: nil)
        aggregatedDelay -= delayStep;
      }
      dispatch_after(delayInNanoSec, dispatch_get_main_queue(), {
        self.animateSwipeableViewsIfNeeded()
      })
    } else {
      self.animateSwipeableViewsIfNeeded()
    }
    
  }
  
  func animateSwipeableViewsIfNeeded() {
    
    var topSwipeableView:UIView!
    if (self.containerView.subviews.count > 0) {
      topSwipeableView = self.containerView.subviews.last! as UIView
    }
    if (topSwipeableView == nil) {return;}
    
    for var i = 0;i < self.containerView.subviews.count; i++ {
      let cover = self.containerView.subviews[i] as UIView
      cover.userInteractionEnabled = false;
    }
    topSwipeableView.userInteractionEnabled = true;
    
    if let recognizers = topSwipeableView.gestureRecognizers {
      for recognizer in recognizers {
        if (recognizer.state != UIGestureRecognizerState.Possible) {
          return;
        }
      }
    }
    
    if (self.isRotationEnabled) {
      // rotation
      let numSwipeableViews = self.containerView.subviews.count;
      if numSwipeableViews >= 1 {
        if self.swipeableViewSnapBehavior != nil {
            self.animator.removeBehavior(self.swipeableViewSnapBehavior)
        }
        self.swipeableViewSnapBehavior = self.snapBehaviorThatSnapView(self.containerView.subviews[numSwipeableViews-1] as UIView, point: self.swipeableViewsCenter)
        self.animator.addBehavior(self.swipeableViewSnapBehavior)
      }
      let rotationCenterOffset = CGPointMake(0, CGRectGetHeight(topSwipeableView.frame) * self.rotationRelativeYOffsetFromCenter)
      if (numSwipeableViews >= 2) {
        self.rotateView(self.containerView.subviews[numSwipeableViews-2] as UIView, degree: Float(self.rotationDegree), offset: rotationCenterOffset , animated: true)
      }
      if (numSwipeableViews>=3) {
        self.rotateView(self.containerView.subviews[numSwipeableViews-3] as UIView, degree: Float(-self.rotationDegree), offset: rotationCenterOffset , animated: true)
      }
    }
  }
  
  
  func signum(n:CGFloat) -> NSInteger { return (n < 0) ? -1 : (n > 0) ? +1 : 0; }
  
  func handlePan(recognizer:UIPanGestureRecognizer) {
    
    let translation = recognizer.translationInView(self)
    let location = recognizer.locationInView(self)
    let swipeableView = recognizer.view
    
    if (recognizer.state == UIGestureRecognizerState.Began) {
      self.createAnchorViewForCover(swipeableView!, location: location, shouldAttachToPoint: true)
      if (self.delegate != nil) {
        self.delegate.containerSwipingCard(self, card: swipeableView!, location: location, translation: translation)
      }
    }
    
    if (recognizer.state == UIGestureRecognizerState.Changed) {
      self.anchorViewAttachmentBehavior.anchorPoint = location;
      if (self.delegate != nil) {
        self.delegate.containerSwipingCard(self, card: swipeableView!, location: location, translation: translation)
      }
    }
    
    if(recognizer.state == UIGestureRecognizerState.Ended || recognizer.state == UIGestureRecognizerState.Cancelled) {
      
      let velocity = recognizer.velocityInView(self)
      let velocityMagnitude = sqrt(pow(velocity.x,2)+pow(velocity.y,2))
      let normalizedVelocity = CGPointMake(velocity.x / velocityMagnitude, velocity.y / velocityMagnitude)
      if ((abs(translation.x) > self.relativeDisplacementThreshold*self.bounds.size.width //displacement
        || velocityMagnitude > self.escapeVelocityThreshold)   //velocity
        && (signum(translation.x)==signum(normalizedVelocity.x)) //sign X
        && (signum(translation.y)==signum(normalizedVelocity.y)) //sign Y
        && abs(normalizedVelocity.y) < 0.8) {    // confine veritcal direction
          let scale:CGFloat = velocityMagnitude > self.escapeVelocityThreshold ? velocityMagnitude:self.pushVelocityMagnitude
          let x2 = translation.x * translation.x
          let y2 = translation.y * translation.y
          let translationMagnitude = sqrtf(Float(x2)+Float(y2))
          let vx = Float(translation.x) / translationMagnitude * Float(scale)
          let vy = Float(translation.y) / translationMagnitude * Float(scale)
          let direction = CGVectorMake(CGFloat(vx), CGFloat(vy))
          self.pushAnchorViewForCover(swipeableView!, direction: direction, collisionrect: self.collisionRect)
      }
      else {
        self.animator.removeBehavior(self.swipeableViewAttachmentBehavior)
        self.animator.removeBehavior(self.anchorViewAttachmentBehavior)
        self.anchorView.removeFromSuperview()
        self.swipeableViewSnapBehavior = self.snapBehaviorThatSnapView(swipeableView, point: self.swipeableViewsCenter)
        self.animator.addBehavior(self.swipeableViewSnapBehavior)
      }
      
      if (self.delegate != nil) {
        self.delegate.containerViewDidEndSwipingCard(self, card: swipeableView!, location: location)
      }
    }
  }
  
  
  
  
  func swipeTopViewToLeft(left:Bool) {
    
    let topSwipeableView:UIView! = self.containerView.subviews.last! as UIView
    if (topSwipeableView == nil) {return;}
    
    let location = CGPointMake(topSwipeableView.center.x, topSwipeableView.center.y*(1+self.manualSwipeRotationRelativeYOffsetFromCenter));
    self.createAnchorViewForCover(topSwipeableView, location: location, shouldAttachToPoint: true)
    var dd = 1
    if (left) {
      dd = -1
    }
    let direction = CGVectorMake(CGFloat(dd) * self.escapeVelocityThreshold, 0);
    self.pushAnchorViewForCover(topSwipeableView, direction: direction, collisionrect: self.collisionRect)
    
  }
  
  func collisionBehaviorThatBoundsView(view:UIView!, rect:CGRect) -> UICollisionBehavior! {
    if (view == nil) {return nil;}
    let collisionBehavior = UICollisionBehavior(items:[view])
    let collisionBound = UIBezierPath(rect: rect)
    collisionBehavior.addBoundaryWithIdentifier("c", forPath: collisionBound)
    collisionBehavior.collisionMode = UICollisionBehaviorMode.Boundaries;
    return collisionBehavior;
  }
  func pushBehaviorThatPushView(view:UIView!,direction:CGVector) -> UIPushBehavior! {
    if (view == nil) {return nil;}
    let pushBehavior = UIPushBehavior(items: [view], mode: UIPushBehaviorMode.Instantaneous)
    pushBehavior.pushDirection = direction;
    return pushBehavior;
  }
  func snapBehaviorThatSnapView(view:UIView!,point:CGPoint) -> UISnapBehavior! {
    if (view == nil) {return nil;}
    let snapBehavior = UISnapBehavior(item: view, snapToPoint: point)
    snapBehavior.damping = 0.75; /* Medium oscillation */
    return snapBehavior;
  }
  func attachmentBehaviorThatAnchorsView(aView:UIView!, anchorview:UIView) -> UIAttachmentBehavior! {
    if (aView == nil) {return nil;}
    let anchorPoint = anchorview.center;
    let p = self.convertPoint(aView.center, toView: self)
    let attachment = UIAttachmentBehavior(item: aView, offsetFromCenter: UIOffsetMake(-(p.x-anchorPoint.x),-(p.y-anchorPoint.y)), attachedToItem: anchorview, offsetFromCenter: UIOffsetMake(0,0))
    attachment.length = 0;
    return attachment;
  }
  func attachmentBehaviorThatAnchorsView(aView:UIView!,aPoint:CGPoint) -> UIAttachmentBehavior! {
    if (aView == nil) {return nil;}
    let p = aView.center;
    let attachmentBehavior = UIAttachmentBehavior(item: aView, offsetFromCenter: UIOffsetMake(-(p.x-aPoint.x), -(p.y-aPoint.y)), attachedToAnchor: aPoint)
    attachmentBehavior.damping = 100;
    attachmentBehavior.length = 0;
    return attachmentBehavior;
  }
  
  func createAnchorViewForCover(swipeableView:UIView,location:CGPoint,shouldAttachToPoint:Bool) {
    self.animator.removeBehavior(self.swipeableViewSnapBehavior)
    self.swipeableViewSnapBehavior = nil;
    
    self.anchorView = UIView(frame: CGRectMake(location.x-500, location.y-500, 1000, 1000))
    self.anchorView.backgroundColor = UIColor.blueColor()
    self.anchorView.hidden = !self.isAnchorViewVisiable
    self.anchorContainerView.addSubview(self.anchorView)
    let attachToView = self.attachmentBehaviorThatAnchorsView(swipeableView, anchorview: self.anchorView)
    self.animator.addBehavior(attachToView)
    self.swipeableViewAttachmentBehavior = attachToView;
    
    if (shouldAttachToPoint) {
      let attachToPoint = self.attachmentBehaviorThatAnchorsView(swipeableView, aPoint: location)
      self.animator.addBehavior(attachToPoint)
      self.anchorViewAttachmentBehavior = attachToPoint;
    }
  }
  
  func pushAnchorViewForCover(swipeableView:UIView,direction:CGVector,collisionrect:CGRect) {
    
    if (direction.dx > 0) {
      if (self.delegate != nil) {
        self.delegate.containerViewDidSwipeRight(self, swipeableView)
      }
    } else {
      if (self.delegate != nil) {
        self.delegate.containerViewDidSwipeLeft(self, swipeableView)
      }
    }
    //    NSLog(@"pushing cover to direction: %f, %f", direction.dx, direction.dy);
    self.animator.removeBehavior(self.anchorViewAttachmentBehavior)
    
    let collisionBehavior = self.collisionBehaviorThatBoundsView(self.anchorView, rect: collisionrect)
    collisionBehavior.collisionDelegate = self;
    self.animator.addBehavior(collisionBehavior)
    
    let pushBehavior = self.pushBehaviorThatPushView(self.anchorView,direction: direction)
    self.animator.addBehavior(pushBehavior)
    
    self.reuseCoverContainerView.addSubview(self.anchorView)
    self.reuseCoverContainerView.addSubview(swipeableView)
    self.reuseCoverContainerView.sendSubviewToBack(swipeableView)
    self.anchorView = nil;
    
    self.loadNextSwipeableViewsIfNeeded(false)
    
  }
  
  
  // MARK: UICollisionBehaviorDelegate
  func collisionBehavior(behavior: UICollisionBehavior, endedContactForItem item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying?) {
    
    let viewsToRemove = NSMutableArray()
    for aBehavior in self.animator.behaviors {
      if let aConvertedBehavior = aBehavior as? UIAttachmentBehavior {
        let items = aConvertedBehavior.items
        if (items.contains{ $0 === item }) {
          self.animator.removeBehavior(aBehavior as! UIAttachmentBehavior)
          viewsToRemove.addObjectsFromArray(items as [AnyObject])
        }
      }
      if let aConvertedBehavior = aBehavior as? UIPushBehavior {
        let items = aConvertedBehavior.items
        if (items.contains{ $0 === item }) {
          self.animator.removeBehavior(aBehavior as! UIPushBehavior)
          viewsToRemove.addObjectsFromArray(items)
        }
      }
      if let aConvertedBehavior = aBehavior as? UICollisionBehavior {
        let items = aConvertedBehavior.items
        if (items.contains{ $0 === item }) {
          self.animator.removeBehavior(aBehavior as! UICollisionBehavior)
          viewsToRemove.addObjectsFromArray(items)
        }
      }
    }
    
    for view in viewsToRemove {
      view.removeFromSuperview()
    }
  }
  
  
  func degreesToRadians(degrees:Float) -> Float {
    return degrees * Float(M_PI) / 180;
  }
  func radiansToDegrees(radians:Float) -> Float {
    return radians * 180 / Float(M_PI);
  }
  
  func nextSwipeableView() -> UIView! {
    var nextView:UIView! = nil;
    if (self.dataSource != nil) {
      nextView = self.dataSource.nextCardViewForContainerView(self)
    }
    if (nextView != nil) {
      nextView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: "handlePan:"))
    }
    return nextView;
  }
  
  func rotateView(view:UIView, degree:Float,offset:CGPoint, animated:Bool) {
    var duration = 0.4
    if (!animated) {duration = 0;}
    let rotationRadian = self.degreesToRadians(degree)
    UIView.animateWithDuration(duration, animations: {
      view.center = self.swipeableViewsCenter
      var transform = CGAffineTransformMakeTranslation(offset.x, offset.y)
      transform = CGAffineTransformRotate(transform, CGFloat(rotationRadian))
      transform = CGAffineTransformTranslate(transform,-offset.x,-offset.y)
      view.transform=transform;
    })
    
  }
  
  
  
  
  
}












