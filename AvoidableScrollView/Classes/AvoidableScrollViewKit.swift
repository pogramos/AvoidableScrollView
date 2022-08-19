//
//  AvoidableScrollViewKit.swift
//  Example
//
//  Created by Guilherme Ramos on 11/12/18.
//  Copyright © 2018 Guilherme Ramos. All rights reserved.
//

import UIKit

typealias AvoidableScrollViewBlockType = () -> Void
typealias AvoidableScrollViewScrollType = (UIScrollView & UITextFieldDelegate & UITextViewDelegate)

final class AvoidableScrollViewKit {
  weak var scrollView: AvoidableScrollViewScrollType!

  var block: AvoidableScrollViewBlockType?

  init(with scrollView: AvoidableScrollViewScrollType, block: AvoidableScrollViewBlockType? = nil) {
    self.block = block
    self.scrollView = scrollView
  }

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

  func register() {
    NotificationCenter.default
      .addObserver(self,
                   selector: #selector(avoidableSvKeyboardWillShow(notification:)),
                   name: UIResponder.keyboardWillShowNotification,
                   object: nil)
    NotificationCenter.default
      .addObserver(self,
                   selector: #selector(avoidableSvKeyboardWillHide(notification:)),
                   name: UIResponder.keyboardWillHideNotification,
                   object: nil)
    NotificationCenter.default
      .addObserver(self,
                   selector: #selector(scrollToActiveTextField),
                   name: UITextView.textDidBeginEditingNotification,
                   object: nil)
    NotificationCenter.default
      .addObserver(self,
                   selector: #selector(scrollToActiveTextField),
                   name: UITextField.textDidBeginEditingNotification,
                   object: nil)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  func cancelPreviousRequest() {
    NSObject.cancelPreviousPerformRequests(withTarget: self,
                                           selector: #selector(avoidableSvAssignTextDelegateForViews(beneath:)),
                                           object: scrollView)
  }

  @objc func scrollToActiveTextField() {
    block?()
  }

  @objc func avoidableSvKeyboardWillShow(notification: Notification) {
    if let userInfo = notification.userInfo {
      if let animationDuration = userInfo[kUIKeyboardAnimationDurationUserInfoKey] as? CGFloat {
        keyboardState.animationDuration = animationDuration
      }
      if let _animationCurve = Int(userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? String ?? ""), let animationCurve = UIView.AnimationCurve(rawValue: _animationCurve) {
        keyboardState.animationCurve = animationCurve
      }
      guard let keyboardValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
      let keyboardRect = keyboardValue.cgRectValue
      if keyboardState.ignoringNotifications { return }

      keyboardState.keyboardRect = keyboardRect

      if !keyboardState.keyboardVisible {
        keyboardState.priorContentInset = scrollView.contentInset
        keyboardState.priorScrollIndicatorInsets = scrollView.scrollIndicatorInsets
        keyboardState.priorIsPagingEnabled = scrollView.isPagingEnabled
      }

      keyboardState.keyboardVisible = true
      scrollView.isPagingEnabled = false

      if type(of: scrollView) == AvoidableScrollView.self {
        keyboardState.priorContentSize = scrollView.contentSize
        if scrollView.contentSize == .zero {
          scrollView.contentSize = avoidableSvCalculateContentSizeFromSubviewFrames()
        }
      }
      if let firstResponder = self.avoidableSvFindFirstResponderBeneath(view: scrollView) {
        scrollView.contentInset = self.avoidableSvContentInsetForKeyboard()
        let viewableHeight = scrollView.bounds.height - scrollView.contentInset.top - scrollView.contentInset.bottom
        UIView.animate(withDuration: TimeInterval(keyboardState.animationDuration),
                       delay: 0.01,
                       options: .curveEaseInOut,
                       animations: {
                        self.willStartAnimation()
                        self.scrollView.setContentOffset(CGPoint(x: self.scrollView.contentOffset.x,
                                                                 y: self.avoidableSvOffset(forView: firstResponder,
                                                                             withHeight: viewableHeight)),
                                              animated: false)
                        self.scrollView.scrollIndicatorInsets = self.scrollView.contentInset
                        self.scrollView.layoutIfNeeded()
        }, completion: { (finished) in
          if finished {
            self.didStopAnimation()
          }
        })
      }
    }
  }

  @objc func avoidableSvKeyboardWillHide(notification: Notification) {
    if let userInfo = notification.userInfo {
      guard let keyboardValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
      let keyboardRect = scrollView.convert(keyboardValue.cgRectValue, from: nil)
      if keyboardRect.isEmpty && !keyboardState.animationInProgress {
        return
      }

      if keyboardState.ignoringNotifications { return }
      if !keyboardState.keyboardVisible { return }

      keyboardState.keyboardRect = .zero
      keyboardState.keyboardVisible = false

      UIView.animate(withDuration: TimeInterval(keyboardState.animationDuration),
                     delay: 0.01,
                     options: .curveEaseInOut,
                     animations: {
                      if type(of: self.scrollView) == AvoidableScrollView.self {
                        self.scrollView.contentSize = self.keyboardState.priorContentSize
                      }

                      self.scrollView.contentInset = self.keyboardState.priorContentInset
                      self.scrollView.scrollIndicatorInsets = self.keyboardState.priorScrollIndicatorInsets
                      self.scrollView.isPagingEnabled = self.keyboardState.priorIsPagingEnabled
                      self.scrollView.layoutIfNeeded()
      })
    }
  }

  @objc func willStartAnimation() {
    keyboardState.animationInProgress = true
  }

  @objc func didStopAnimation() {
    keyboardState.animationInProgress = false
  }

  // MARK: - Private avoidableScrollView methods

  func avoidableSvFocusNextTextField() -> Bool {
    if let firstResponder = avoidableSvFindFirstResponderBeneath(view: scrollView) {
      if let view = avoidableSvFindNextInputViewAfter(view: firstResponder, beneath: scrollView) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          let state = self.keyboardState
          state.ignoringNotifications = true
          view.becomeFirstResponder()
          state.ignoringNotifications = false
        }
        return true
      }
    }
    return false
  }

  func avoidableSvScrollToActiveFirstResponder() {
    let state = keyboardState
    if !state.keyboardVisible { return }
    if let firstResponder = avoidableSvFindFirstResponderBeneath(view: scrollView) {
      state.ignoringNotifications = true
      let visibleSpace = scrollView.bounds.height - scrollView.contentInset.top - scrollView.contentInset.bottom
      let idealOffset = CGPoint(x: scrollView.contentOffset.x,
                                y: avoidableSvOffset(forView: firstResponder,
                                                     withHeight: visibleSpace))
      UIView.animate(withDuration: TimeInterval(state.animationDuration), animations: {
        self.scrollView.contentOffset = idealOffset
      }, completion: { _ in
        state.ignoringNotifications = false
      })
    }
  }

  func avoidableSvUpdateContentInset() {
    let state = keyboardState
    if state.keyboardVisible {
      scrollView.contentInset = avoidableSvContentInsetForKeyboard()
    }
  }

  func avoidableSvUpdateFromContentSizeChange() {
    let state = keyboardState
    if state.keyboardVisible {
      state.priorContentSize = scrollView.contentSize
      scrollView.contentInset = avoidableSvContentInsetForKeyboard()
    }
  }

  func avoidableSvCalculateContentSizeFromSubviewFrames() -> CGSize {
    let wasShowingVerticalScrollIndicator = scrollView.showsVerticalScrollIndicator
    let wasShowingHorizontalScrollIndicator = scrollView.showsHorizontalScrollIndicator

    scrollView.showsVerticalScrollIndicator = false
    scrollView.showsHorizontalScrollIndicator = false

    var rect: CGRect = .zero

    for view in scrollView.subviews {
      rect = rect.union(view.frame)
    }

    rect.size.height += kCalculatedContentPadding

    scrollView.showsVerticalScrollIndicator = wasShowingVerticalScrollIndicator
    scrollView.showsHorizontalScrollIndicator = wasShowingHorizontalScrollIndicator

    return rect.size
  }

  func avoidableSvFindFirstResponderBeneath(view: UIView) -> UIView? {
    for subview in view.subviews {
      if subview.isFirstResponder {
        return subview
      }
      if let result = avoidableSvFindFirstResponderBeneath(view: subview) {
        return result
      }
    }
    return nil
  }

  func avoidableSvFindNextInputViewAfter(view priorView: UIView, beneath view: UIView) -> UIView? {
    var candidate: UIView? = nil
    avoidableSvFindNextInputViewAfter(view: priorView, beneath: view, bestCandidate: &candidate)
    return candidate
  }

  func avoidableSvFindNextInputViewAfter(view priorView: UIView, beneath view: UIView, bestCandidate candidate: inout UIView?) {
    let priorFrame = scrollView.convert(priorView.frame, from: priorView.superview)
    var candidateFrame: CGRect = .zero
    if let candidate = candidate {
      candidateFrame = scrollView.convert(candidate.frame, from: candidate.superview)
    }
    var candidateHeuristic = avoidableSvNextInputViewHeuristicForView(frame: candidateFrame)

    for subview in view.subviews {
      if avoidableSvIsValidKeyCandidate(view: subview) {
        let frame = scrollView.convert(subview.frame, from: view)
        let heuristic = avoidableSvNextInputViewHeuristicForView(frame: frame)

        if subview != priorView
          && ((fabs(frame.minY - priorFrame.minY) < CGFloat.ulpOfOne)
            && frame.minX > priorFrame.minX || frame.minY > priorFrame.minY)
          && (candidate != nil || heuristic > candidateHeuristic) {
          candidate = subview
          candidateHeuristic = heuristic
        }
      } else {
        avoidableSvFindNextInputViewAfter(view: priorView, beneath: subview, bestCandidate: &candidate)
      }
    }
  }

  func avoidableSvNextInputViewHeuristicForView(frame: CGRect) -> CGFloat {
    return (-frame.minY * 1000) + (-frame.minX)
  }

  func avoidableSvHiddenOrUserInteractionNotEnable(view: UIView?) -> Bool {
    var view = view // make the parameter a mutable variable
    while view != nil {
      if let view = view, view.isHidden || !view.isUserInteractionEnabled {
        return true
      }
      view = view?.superview
    }
    return false
  }

  func avoidableSvIsValidKeyCandidate(view: UIView?) -> Bool {
    if avoidableSvHiddenOrUserInteractionNotEnable(view: view) { return false }

    if let textField = view as? UITextField, textField.isEnabled {
      return true
    }

    if let textView = view as? UITextView, textView.isEditable {
      return true
    }

    return false
  }

  @objc func avoidableSvAssignTextDelegateForViews(beneath view: UIView) {
    for subview in view.subviews {
      if let textField = subview as? UITextField {
        avoidableSvInitialize(view: textField)
      } else if let textField = subview as? UITextField {
        avoidableSvInitialize(view: textField)
      } else {
        avoidableSvAssignTextDelegateForViews(beneath: subview)
      }
    }
  }

  func avoidableSvContentInsetForKeyboard() -> UIEdgeInsets {
    let state = keyboardState
    var newInset = scrollView.contentInset
    let keyboardRect = state.keyboardRect
    newInset.bottom = keyboardRect.height - max(keyboardRect.maxY - scrollView.bounds.maxY, 0)
    return newInset
  }

  func avoidableSvOffset(forView view: UIView, withHeight height: CGFloat) -> CGFloat {
    let contentSize = scrollView.contentSize
    var offset: CGFloat = 0.0
    var subviewRect: CGRect = view.convert(view.bounds, to: scrollView)
    var padding: CGFloat = 0.0
    var contentInset: UIEdgeInsets = .zero

    if #available(iOS 11.0, *) {
      contentInset = scrollView.adjustedContentInset
    } else {
      contentInset = scrollView.contentInset
    }

    func centerViewInViewableArea() {
      // center the subview in the visible space
      padding = (height - subviewRect.height) / 2

      if padding < kMinimumScrollOffsetPadding {
        padding = kMinimumScrollOffsetPadding
      }

      // compensates the padding and the top padding (if there's one)
      offset = subviewRect.minY - padding - contentInset.top
    }

    if let textInput = view as? UITextInput {
      if let position = textInput.selectedTextRange?.start {
        let positionRect = scrollView.convert(textInput.caretRect(for: position), from: textInput as? UIView)
        padding = (height - positionRect.height) / 2
        if padding < kMinimumScrollOffsetPadding {
          padding = kMinimumScrollOffsetPadding
        }
        offset = positionRect.minY - padding - contentInset.top
      } else {
        centerViewInViewableArea()
      }
    } else {
      centerViewInViewableArea()
    }

    let maxOffset = contentSize.height - height - contentInset.top
    if offset > maxOffset {
      offset = maxOffset
    }
    if offset < -contentInset.top {
      offset = -contentInset.top
    }

    return offset
  }

  func avoidableSvInitialize(view: UIView) {
    guard let textField = view as? UITextField else { return }
    if textField.returnKeyType == .default || textField.returnKeyType == .next && textField.delegate === scrollView {
      textField.delegate = scrollView
      if avoidableSvFindNextInputViewAfter(view: textField, beneath: scrollView) != nil {
        textField.returnKeyType = .next
      } else {
        textField.returnKeyType = .done
      }
    }
  }
}
