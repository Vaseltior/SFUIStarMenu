//
// The MIT License (MIT)
//
// Copyright (c) 2015 Samuel GRAU
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

//
//  SFUIStarMenu.swift
//  SFUIStarMenu
//
//  Created by Samuel Grau on 27/03/2015.
//  Copyright (c) 2015 Samuel GRAU. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore

public protocol SFUIStarMenuItemDelegate {
    func sfUIStarMenuItemTouchesBegan(item: SFUIStarMenuItem)
    func sfUIStarMenuItemTouchesEnded(item: SFUIStarMenuItem)
}

public extension CGRect {
    func scaleRect(coefficient n: CGFloat) -> CGRect {
        return CGRectMake(
            (self.size.width - self.size.width * n)/2.0,
            (self.size.height - self.size.height * n) / 2.0,
            self.size.width * n,
            self.size.height * n
        )
    }
}

///
/// This class describe the items that should
/// be used and expanded by the exploding menu
///
public class SFUIStarMenuItem: UIView {
    
    /// MARK: - Properties -
    
    // default is NO. this gets set/cleared automatically when touch enters/exits during tracking and cleared on up
    public var highlighted: Bool = false {
        didSet {
            self.setNeedsDisplay()
            /*if let cv = self.contentView {
            cv.highlighted = self.highlighted
            }*/
        }
    }
    
    public var contentSize: CGSize = CGSizeZero
    public var contentView: UIView? = nil {
        willSet (newValue) {
            if newValue == nil {
                if let cv = self.contentView {
                    cv.removeFromSuperview()
                }
            }
        }
        
        didSet {
            if let cv = self.contentView {
                self.addSubview(cv)
            }
        }
    }
    
    public var delegate: SFUIStarMenuItemDelegate? = nil
    
    public var startPoint: CGPoint = CGPointZero
    public var endPoint: CGPoint = CGPointZero
    public var nearPoint: CGPoint = CGPointZero // near
    public var farPoint: CGPoint = CGPointZero // far
    
    /// MARK: - Initialzation methods -
    
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        self.commonInit()
    }
    
    ///
    /// The common initialization called when inited
    ///
    func commonInit() {
        // Do something
    }
    
    
    /// MARK: - Layout -
    
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        let width = self.contentSize.width
        let height = self.contentSize.height
        
        self.bounds = CGRectMake(0, 0, width, height)
        
        if let cv = self.contentView {
            cv.frame = CGRectMake(
                (CGRectGetWidth(self.bounds) - CGRectGetWidth(cv.bounds))/2.0,
                (CGRectGetHeight(self.bounds) - CGRectGetHeight(cv.bounds))/2.0,
                width,
                height
            )
        }
    }
    
    /// MARK: - UITouch Delegate -
    
    
    public override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)
        self.highlighted = true
        self.delegate?.sfUIStarMenuItemTouchesBegan(self)
    }
    
    public override func touchesCancelled(touches: NSSet!, withEvent event: UIEvent!) {
        super.touchesCancelled(touches, withEvent: event)
        self.highlighted = false
    }
    
    public override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        super.touchesEnded(touches, withEvent: event)
        self.highlighted = false
        if let touch = touches.anyObject() as? UITouch {
            let location: CGPoint = touch.locationInView(self)
            if (CGRectContainsPoint(self.bounds.scaleRect(coefficient: 2.0), location)) {
                self.delegate?.sfUIStarMenuItemTouchesEnded(self)
            }
        }
    }
    
    public override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        super.touchesMoved(touches, withEvent: event)
        
        // if move out of 2x rect, cancel highlighted.
        if let touch = touches.anyObject() as? UITouch {
            let location: CGPoint = touch.locationInView(self)
            if (!CGRectContainsPoint(self.bounds.scaleRect(coefficient: 2.0), location)) {
                self.highlighted = false
            }
        }
    }
}

public protocol SFUIStarMenuDelegate {
    func sfUIStarMenu(menu: SFUIStarMenu, didSelectIndex index:Int)
    func sfUIStarMenuDidFinishExpandAnimation(menu: SFUIStarMenu)
    func sfUIStarMenuDidFinishFoldAnimation(menu: SFUIStarMenu)
    func sfUIStarMenuWillAnimateExpandAnimation(menu: SFUIStarMenu)
    func sfUIStarMenuWillAnimateFoldAnimation(menu: SFUIStarMenu)
}


///
/// This class mimic the behavior of the Path menu
///
public class SFUIStarMenu: SFUIStarControl, SFUIStarMenuItemDelegate {
    
    /// MARK: - Properties -
    
    public var menuItems: [SFUIStarMenuItem] = [SFUIStarMenuItem]()
    public var triggeringButton:SFUIStarMenuItem? = nil
    public var delegate: SFUIStarMenuDelegate? = nil
    
    public var nearRadius: CGFloat = 0.0
    public var endRadius: CGFloat = 0.0
    public var farRadius: CGFloat = 0.0
    
    public var startPoint: CGPoint = CGPointZero {
        didSet {
            if let triggeringButton = self.triggeringButton {
                triggeringButton.center = self.startPoint
            }
        }
    }
    
    public var timeOffset: NSTimeInterval = 0.0
    public var rotateAngle: CGFloat = 0.0
    public var menuWholeAngle: CGFloat = 0.0
    public var expandRotation: CGFloat = 0.0
    public var closeRotation: CGFloat = 0.0
    public var animationDuration: NSTimeInterval = 0.0
    public var rotateAddButton: Bool = false
    
    var isAnimating: Bool = false
    var expanded: Bool = false
    
    func isExpanded() -> Bool {
        return self.expanded
    }

    let kSFUIStarMenuDefaultNearRadius: CGFloat = 110.0
    let kSFUIStarMenuDefaultEndRadius: CGFloat = 120.0
    let kSFUIStarMenuDefaultFarRadius: CGFloat = 140.0
    let kSFUIStarMenuDefaultStartPointX: CGFloat = 160.0
    let kSFUIStarMenuDefaultStartPointY: CGFloat = 240.0
    let kSFUIStarMenuDefaultTimeOffset: NSTimeInterval = 0.036
    let kSFUIStarMenuDefaultRotateAngle: CGFloat = 0.0
    let kSFUIStarMenuDefaultMenuWholeAngle: CGFloat = CGFloat(M_PI * 2.0)
    let kSFUIStarMenuDefaultExpandRotation: CGFloat = CGFloat(M_PI)
    let kSFUIStarMenuDefaultCloseRotation: CGFloat = CGFloat(M_PI * 2.0)
    let kSFUIStarMenuDefaultAnimationDuration: NSTimeInterval = 0.5
    let kSFUIStarMenuStartMenuDefaultAnimationDuration: NSTimeInterval = 0.3

    /// MARK: - Initialzation methods -
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        self.commonInit()
    }
    
    public convenience init(frame: CGRect, triggeringItem: SFUIStarMenuItem, menuItems: [SFUIStarMenuItem]) {
        self.init(frame: frame)
        
        self.menuItems.removeAll(keepCapacity: false)
        self.menuItems += menuItems
        self.configureMenuItems()
        
        // assign startItem to "Add" Button.
        self.triggeringButton = triggeringItem
        self.triggeringButton!.delegate = self
        self.triggeringButton!.center = self.startPoint
        self.addSubview(self.triggeringButton!)
    }
    
    ///
    /// The common initialization called when inited
    ///
    override func commonInit() {
        self.backgroundColor = UIColor.clearColor()
        self.nearRadius = kSFUIStarMenuDefaultNearRadius
        self.endRadius = kSFUIStarMenuDefaultEndRadius
        self.farRadius = kSFUIStarMenuDefaultFarRadius
        self.timeOffset = kSFUIStarMenuDefaultTimeOffset
        self.rotateAngle = kSFUIStarMenuDefaultRotateAngle
        self.menuWholeAngle = kSFUIStarMenuDefaultMenuWholeAngle
        self.startPoint = CGPointMake(kSFUIStarMenuDefaultStartPointX, kSFUIStarMenuDefaultStartPointY)
        self.expandRotation = kSFUIStarMenuDefaultExpandRotation
        self.closeRotation = kSFUIStarMenuDefaultCloseRotation
        self.animationDuration = kSFUIStarMenuDefaultAnimationDuration
        self.rotateAddButton = true
    }
    
    
    func configureMenuItems() {
        // clean subviews
        for v in self.subviews {
            if (v.tag >= 1000) {
                v.removeFromSuperview()
            }
        }
    }

    
    /// MARK: - Public maethods -
    
    
    func menuItemAtIndex(index: Int) -> SFUIStarMenuItem? {
        if (index <= 0 || index >= self.menuItems.count) {
            return nil
        }
        
        return self.menuItems[index]
    }
    
    private var flag: Int = 0
    private var timer: NSTimer? = nil
    
    ///
    ///
    ///
    private func setUpMenu() {
        let count = self.menuItems.count
        for i in 0..<count {
            let item = self.menuItems[i]
            item.tag = 1000 + i
            item.startPoint = startPoint
            
            // avoid overlap
            if (self.menuWholeAngle >= CGFloat(M_PI * 2)) {
                self.menuWholeAngle = menuWholeAngle - menuWholeAngle / CGFloat(count)
            }
            
            let v = Float(i) * Float(menuWholeAngle) / Float(count - 1)
            let endPoint = CGPointMake(
                startPoint.x + self.endRadius * CGFloat(sinf(v)),
                startPoint.y - self.endRadius * CGFloat(cosf(v))
            )
            item.endPoint = SFUIStarMenu.rotateCGPointAroundCenter(endPoint, center: startPoint, angle: rotateAngle)
            let nearPoint = CGPointMake(
                startPoint.x + self.nearRadius * CGFloat(sinf(v)),
                startPoint.y - self.nearRadius * CGFloat(cosf(v))
            )
            item.nearPoint = SFUIStarMenu.rotateCGPointAroundCenter(nearPoint, center: startPoint, angle: rotateAngle)
            let farPoint = CGPointMake(
                startPoint.x + self.farRadius * CGFloat(sinf(v)),
                startPoint.y - self.farRadius * CGFloat(cosf(v))
            )
            item.farPoint = SFUIStarMenu.rotateCGPointAroundCenter(farPoint, center: startPoint, angle: rotateAngle)
            item.center = item.startPoint
            item.delegate = nil
            item.delegate = self
            
            if let triggeringButton = self.triggeringButton {
                self.insertSubview(item, belowSubview:triggeringButton)
            }
        }
    }

    ///
    ///
    ///
    private class func rotateCGPointAroundCenter(point: CGPoint, center: CGPoint, angle: CGFloat) -> CGPoint {
        let translation = CGAffineTransformMakeTranslation(center.x, center.y)
        let rotation = CGAffineTransformMakeRotation(angle)
        let transformGroup = CGAffineTransformConcat(CGAffineTransformConcat(CGAffineTransformInvert(translation), rotation), translation)
        return CGPointApplyAffineTransform(point, transformGroup)
    }
    
    
    ///
    ///
    ///
    private func setExpanded(expanded: Bool) {
        
        if (expanded) {
            self.setUpMenu()
            self.delegate?.sfUIStarMenuWillAnimateExpandAnimation(self)
        }
        
        self.delegate?.sfUIStarMenuWillAnimateFoldAnimation(self)
        
        // rotate add button
        if (self.rotateAddButton) {
            let angle: CGFloat = self.isExpanded() ? CGFloat(-M_PI_4) : 0.0
            
            if let tb = self.triggeringButton {
                UIView.animateWithDuration(self.kSFUIStarMenuStartMenuDefaultAnimationDuration, animations: { () -> Void in
                    tb.transform = CGAffineTransformMakeRotation(angle)
                })
            }
            
        }
        
        // expand or close animation
        if self.timer == nil {
            self.flag = self.isExpanded() ? 0 : (self.menuItems.count - 1)
            let selector = self.isExpanded() ? Selector("expandAnimation") : Selector("foldAnimation")
            
            // Adding timer to runloop to make sure UI event won't block the timer from firing
            let timer = NSTimer(timeInterval: timeOffset, target: self, selector: selector, userInfo: nil, repeats: true)
            self.timer = timer
            NSRunLoop.currentRunLoop().addTimer(self.timer!, forMode:NSRunLoopCommonModes)
            self.isAnimating = true
        }
        
    }
    
    ///
    ///
    ///
    func expandAnimation() {
        
        if (self.flag == self.menuItems.count) {
            self.isAnimating = false
            self.timer?.invalidate()
            self.timer = nil
            return
        }
        
        let tag = 1000 + self.flag
        if let item = self.viewWithTag(tag) as? SFUIStarMenuItem {
            let rotateAnimation = CAKeyframeAnimation(keyPath:"transform.rotation.z")
            
            rotateAnimation.values = [NSNumber(float:Float(expandRotation)), NSNumber(float:0.0)]
            rotateAnimation.duration = animationDuration
            rotateAnimation.keyTimes = [NSNumber(float:0.3), NSNumber(float:0.4)]
            
            let positionAnimation: CAKeyframeAnimation = CAKeyframeAnimation(keyPath:"position")
            positionAnimation.duration = animationDuration
            var path = CGPathCreateMutable()
            CGPathMoveToPoint(path, nil, item.startPoint.x, item.startPoint.y)
            CGPathAddLineToPoint(path, nil, item.farPoint.x, item.farPoint.y)
            CGPathAddLineToPoint(path, nil, item.nearPoint.x, item.nearPoint.y)
            CGPathAddLineToPoint(path, nil, item.endPoint.x, item.endPoint.y)
            positionAnimation.path = path
            
            let animationgroup = CAAnimationGroup()
            animationgroup.animations = [positionAnimation, rotateAnimation]
            animationgroup.duration = animationDuration
            animationgroup.fillMode = kCAFillModeForwards
            animationgroup.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseIn)
            animationgroup.delegate = self
            
            if (self.flag == self.menuItems.count - 1) {
                animationgroup.setValue("firstAnimation", forKey:"id")
            }
            
            item.layer.addAnimation(animationgroup, forKey:"Expand")
            item.center = item.endPoint
            item.setNeedsLayout()
        }
        
        self.flag++
    }
    
    ///
    ///
    ///
    func foldAnimation() {
        if (self.flag == -1) {
            self.isAnimating = false
            self.timer?.invalidate()
            self.timer = nil
            return
        }
        
        let tag = 1000 + self.flag
        if let item = self.viewWithTag(tag) as? SFUIStarMenuItem {
            let rotateAnimation = CAKeyframeAnimation(keyPath:"transform.rotation.z")
            
            rotateAnimation.values = [NSNumber(float:0.0), NSNumber(float:0.0)]
            rotateAnimation.duration = animationDuration
            rotateAnimation.keyTimes = [NSNumber(float:0.0), NSNumber(float:0.4), NSNumber(float:0.5)]
            
            let positionAnimation: CAKeyframeAnimation = CAKeyframeAnimation(keyPath:"position")
            positionAnimation.duration = animationDuration
            var path = CGPathCreateMutable()
            CGPathMoveToPoint(path, nil, item.endPoint.x, item.endPoint.y)
            CGPathAddLineToPoint(path, nil, item.farPoint.x, item.farPoint.y)
            CGPathAddLineToPoint(path, nil, item.startPoint.x, item.startPoint.y)
            positionAnimation.path = path
            
            let animationgroup = CAAnimationGroup()
            animationgroup.animations = [positionAnimation, rotateAnimation]
            animationgroup.duration = animationDuration
            animationgroup.fillMode = kCAFillModeForwards
            animationgroup.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseIn)
            animationgroup.delegate = self
            
            if (self.flag == 0) {
                animationgroup.setValue("lastAnimation", forKey:"id")
            }
            
            item.layer.addAnimation(animationgroup, forKey:"Fold")
            item.center = item.startPoint
        }
        
        self.flag--
    }
    
    /// MARK: - UIView's methods -
    
    
    public override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        // if the menu is animating, prevent touches
        if (self.isAnimating) {
            return false
        }
        
        // if the menu state is expanding, everywhere can be touch
        // otherwise, only the add button are can be touch
        if (self.isExpanded()) {
            return true
            
        } else {
            if let triggeringButton = self.triggeringButton {
                let result = CGRectContainsPoint(triggeringButton.frame, point)
                return result
            }
        }
        
        return false
    }
    
    public override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)
    }
    
    
    /// MARK: - SFUIStarMenuItemDelegate -
    
    
    public func sfUIStarMenuItemTouchesBegan(item: SFUIStarMenuItem) {
        if (item == self.triggeringButton) {
            self.expanded = !self.isExpanded()
            self.setExpanded(self.expanded)
        }
    }
  
    public func sfUIStarMenuItemTouchesEnded(item: SFUIStarMenuItem) {
        // exclude the "add" button
        if (item == self.triggeringButton) {
            return
        }
        
        // blowup the selected menu button
        let blowup: CAAnimationGroup = self.blowupAnimationAtPoint(item.center)
        item.layer.addAnimation(blowup, forKey:"blowup")
        item.center = item.startPoint
        
        // shrink other menu buttons
        for i in 0..<self.menuItems.count {
            let otherItem = self.menuItems[i]
            let shrink: CAAnimationGroup = self.shrinkAnimationAtPoint(otherItem.center)
            if (otherItem.tag == item.tag) {
                continue
            }
            otherItem.layer.addAnimation(shrink, forKey:"shrink")
            otherItem.center = otherItem.startPoint
        }
        self.expanded = false
        
        // rotate start button
        let angle: CGFloat = self.isExpanded() ? -CGFloat(M_PI_4) : 0.0
        
        if let tb = self.triggeringButton {
            UIView.animateWithDuration(animationDuration, animations: { () -> Void in
                tb.transform = CGAffineTransformMakeRotation(angle)
            })
        }
        
        self.delegate?.sfUIStarMenu(self, didSelectIndex: item.tag - 1000)
    }
    
    ///
    ///
    ///
    public override func animationDidStop(anim: CAAnimation!, finished flag: Bool) {
        
        if let identifier = anim.valueForKey("id") as? String {
            if identifier == "lastAnimation" {
                self.delegate?.sfUIStarMenuDidFinishFoldAnimation(self)
                
            } else if identifier == "firstAnimation" {
                self.delegate?.sfUIStarMenuDidFinishExpandAnimation(self)
            }
            
        }
    }
    
    /// MARK: - Private methods -
    
    
    ///
    /// Returns a blowup animation
    ///
    /// :param: p Point
    ///
    /// :returns: a blowup animation
    ///
    func blowupAnimationAtPoint(p:CGPoint) -> CAAnimationGroup {
        let positionAnimation: CAKeyframeAnimation = CAKeyframeAnimation(keyPath: "position")
        positionAnimation.values = [NSValue(CGPoint:p)]
        positionAnimation.keyTimes = [NSNumber(float: 0.3)]
        
        let scaleAnimation: CABasicAnimation = CABasicAnimation(keyPath:"transform")
        scaleAnimation.toValue = NSValue(CATransform3D:CATransform3DMakeScale(3, 3, 1))
        
        let opacityAnimation: CABasicAnimation = CABasicAnimation(keyPath:"opacity")
        opacityAnimation.toValue = NSNumber(float:0.0)
        
        let animationgroup: CAAnimationGroup = CAAnimationGroup()
        animationgroup.animations = [positionAnimation, scaleAnimation, opacityAnimation]
        animationgroup.duration = animationDuration
        animationgroup.fillMode = kCAFillModeForwards
        
        return animationgroup
    }
    
    ///
    /// Returns a shrink animation
    ///
    /// :param: p Point
    ///
    /// :returns: a shrink animation
    ///
    func shrinkAnimationAtPoint(p:CGPoint) -> CAAnimationGroup {
        let positionAnimation: CAKeyframeAnimation = CAKeyframeAnimation(keyPath: "position")
        positionAnimation.values = [NSValue(CGPoint:p)]
        positionAnimation.keyTimes = [NSNumber(float: 0.3)]
        
        let scaleAnimation: CABasicAnimation = CABasicAnimation(keyPath:"transform")
        scaleAnimation.toValue = NSValue(CATransform3D:CATransform3DMakeScale(0.01, 0.01, 1))
        
        let opacityAnimation: CABasicAnimation = CABasicAnimation(keyPath:"opacity")
        opacityAnimation.toValue = NSNumber(float:0.0)
        
        let animationgroup: CAAnimationGroup = CAAnimationGroup()
        animationgroup.animations = [positionAnimation, scaleAnimation, opacityAnimation]
        animationgroup.duration = animationDuration
        animationgroup.fillMode = kCAFillModeForwards
        
        return animationgroup
    }

}