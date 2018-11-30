//
//  AvoidableScrollView.swift
//  MobileBanking
//
//  Created by Guilherme Ramos on 28/11/18.
//  Copyright © 2018 BS2. All rights reserved.
//

import UIKit
import ObjectiveC

final public class AvoidableScrollView: UIScrollView, UITextFieldDelegate, UITextViewDelegate {

  let kCalculatedContentPadding: CGFloat = 10
  let kMinimumScrollOffsetPadding: CGFloat = 20

  internal var stateKey: String = "UIKeyboardState"
  internal var kUIKeyboardAnimationDurationUserInfoKey = "UIKeyboardAnimationDurationUserInfoKey"
  var _keyboardState = AvoidableKeyboardState()
  var keyboardState: AvoidableKeyboardState {
    get {
      return _keyboardState
    }
    set(newState) {
      _keyboardState = newState
    }
  }

  override public var frame: CGRect {
    didSet {
      avoidableSvUpdateContentInset()
    }
  }

  override public var contentSize: CGSize {
    didSet {
      avoidableSvUpdateFromContentSizeChange()
    }
  }

  private func setup() {
    NotificationCenter.default.addObserver(self, selector: #selector(avoidableSvKeyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(avoidableSvKeyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(scrollToActiveTextField), name: UITextView.textDidBeginEditingNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(scrollToActiveTextField), name: UITextField.textDidBeginEditingNotification, object: nil)
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }

  override public func awakeFromNib() {
    super.awakeFromNib()
    setup()
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  func contentSizeToFit() {
    contentSize = avoidableSvCalculateContentSizeFromSubviewFrames()
  }

  func focusNextTextField() -> Bool {
    return avoidableSvFocusNextTextField()
  }

  @objc func scrollToActiveTextField() {
    avoidableSvScrollToActiveFirstResponder()
  }

  // MARK: - Events
  override public func willMove(toSuperview newSuperview: UIView?) {
    super.willMove(toSuperview: newSuperview)
    if newSuperview == nil {
      NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(avoidableSvAssignTextDelegateForViews(beneath:)), object: self)
    }
  }

  override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    avoidableSvFindFirstResponderBeneath(view: self)?.resignFirstResponder()
    super.touchesEnded(touches, with: event)
  }

  private func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if !focusNextTextField() {
      textField.resignFirstResponder()
    }
    return true
  }

  override public func layoutSubviews() {
    super.layoutSubviews()

    NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(avoidableSvAssignTextDelegateForViews(beneath:)), object: self)
    perform(#selector(avoidableSvAssignTextDelegateForViews(beneath:)), with: self, afterDelay: 0.1)
  }
}
