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
//  SFUIStarControl.swift
//  SFUIStarMenu
//
//  Created by Samuel Grau on 27/03/2015.
//  Copyright (c) 2015 Samuel GRAU. All rights reserved.
//

import Foundation
import UIKit

public class SFUIStarControl : UIControl {
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    
    public class SFUIStarControlContent {
        var title: String = ""
        
        private var control: SFUIStarControl! = nil
        
        init(control: SFUIStarControl) {
            self.control = control
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    
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
    
    ///
    /// The common initialization called when inited
    ///
    func commonInit() {
        // Do something
    }
    
    private var controlContent: [String:AnyObject] = [String:AnyObject]()
    
    ///
    /// Returns the title for the given state
    ///
    /// :param: state The UIControlState
    ///
    /// :returns: The title for the given state
    ///
    func titleForState(state: UIControlState) -> String {
        return self.contentForState(state).title
    }
    
    ///
    /// Set the title for the given state
    ///
    /// :param: title The title to set for the current state
    /// :param: state The UIControlState
    ///
    func setTitle(title: String, forState state:UIControlState) {
        let content = self.contentForState(state)
        content.title = title
        self.setNeedsDisplay()
    }
    
    ///
    /// Return _YES_ if the control is currently highlighted or selected, otherwise return _NO_
    ///
    /// :returns: Return _YES_ if the control is currently highlighted or selected, otherwise return _NO_
    ///
    func isHighlightedOrSelected() -> Bool {
        return (self.highlighted || self.selected)
    }
    
    /// MARK: - UIAccessibility -
    
    
    /*
    Return YES if the receiver should be exposed as an accessibility element.
    default == NO
    default on UIKit controls == YES
    Setting the property to YES will cause the receiver to be visible to assistive applications.
    */
    public override var isAccessibilityElement: Bool {
        get {
            return true
        }
        
        set (newValue) {
            super.isAccessibilityElement = newValue
        }
    }
    
    /*
    Returns the localized label that represents the element.
    If the element does not display text (an icon for example), this method
    should return text that best labels the element. For example: "Play" could be used for
    a button that is used to play music. "Play button" should not be used, since there is a trait
    that identifies the control is a button.
    default == nil
    default on UIKit controls == derived from the title
    Setting the property will change the label that is returned to the accessibility client.
    */
    public override var accessibilityLabel: String! {
        get {
            return self.titleForCurrentState()
        }
        
        set (newValue) {
            super.accessibilityLabel = newValue
        }
    }
    
    /*
    Returns a UIAccessibilityTraits mask that is the OR combination of
    all accessibility traits that best characterize the element.
    See UIAccessibilityConstants.h for a list of traits.
    When overriding this method, remember to combine your custom traits
    with [super accessibilityTraits].
    default == UIAccessibilityTraitNone
    default on UIKit controls == traits that best characterize individual controls.
    Setting the property will change the traits that are returned to the accessibility client.
    */
    public override var accessibilityTraits: UIAccessibilityTraits {
        get {
            return super.accessibilityTraits | UIAccessibilityTraitButton
        }
        
        set (newValue) {
            super.accessibilityTraits = newValue
        }
    }
    
    /// MARK: - Overrides -
    
    
    // default is NO may be used by some subclasses or by application
    public override var selected: Bool {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    // default is NO. this gets set/cleared automatically when touch enters/exits during tracking and cleared on up
    public override var highlighted: Bool {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    /// MARK: - Private Methods - 
    
    
    private func keyForState(state: UIControlState) -> String {
        let normalKey = "normal"
        let highlighted = "highlighted"
        let selected = "selected"
        let disabled = "disabled"
        
        if (state & .Highlighted) == .Highlighted {
            return highlighted
            
        } else if ( state & .Selected ) == .Selected {
            return selected
            
        } else if ( state & .Disabled ) == .Disabled {
            return disabled
            
        } else {
            return normalKey
        }
    }
    
    private func contentForState(state: UIControlState) -> SFUIStarControlContent {
        let key: String = self.keyForState(state)
        if let content = self.controlContent[key] as? SFUIStarControlContent {
            return content
            
        } else {
            let content = SFUIStarControlContent(control:self)
            self.controlContent[key] = content
            return content
        }
    }
    
    private func contentForCurrentState() -> SFUIStarControlContent {
        var content: SFUIStarControlContent = self.contentForState(.Normal)
        
        if ( self.selected ) {
            content = self.contentForState(.Selected)
            
        } else if ( self.highlighted ) {
            content = self.contentForState(.Highlighted)
            
        } else if ( !self.enabled ) {
            content = self.contentForState(.Disabled)
        }
        
        return content
    }
    
    private func titleForCurrentState() -> String {
        let content = self.contentForCurrentState()
        return content.title ?? self.contentForState(.Normal).title
    }
    
    
    /// MARK: - UITouch Delegate -
    
    
    public override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)
        self.highlighted = true
    }
    
    public override func touchesCancelled(touches: NSSet!, withEvent event: UIEvent!) {
        super.touchesCancelled(touches, withEvent: event)
        self.highlighted = false
    }
    
    public override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        super.touchesEnded(touches, withEvent: event)
        self.highlighted = false
    }
    
    public override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        super.touchesMoved(touches, withEvent: event)
        self.highlighted = true
    }
}
