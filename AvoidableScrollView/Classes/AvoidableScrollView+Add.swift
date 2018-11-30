//
//  AvoidableScrollView+Add.swift
//  MobileBanking
//
//  Created by Guilherme Ramos on 28/11/18.
//  Copyright © 2018 BS2. All rights reserved.
//

import UIKit

typealias AvoidableScrollViewAdditions = AvoidableScrollView
extension AvoidableScrollViewAdditions {
  // MARK: - Notification Handlers
  @objc func avoidableSvKeyboardWillShow(notification: Notification) {
    if let userInfo = notification.userInfo {
      if let animationDuration = userInfo[kUIKeyboardAnimationDurationUserInfoKey] as? CGFloat {
        keyboardState.animationDuration = animationDuration
      }
      if let _animationCurve = Int(userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? String ?? ""),
        let animationCurve = UIView.AnimationCurve(rawValue: _animationCurve) {
        keyboardState.animationCurve = animationCurve
      }
      guard let keyboardValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
      let keyboardRect = keyboardValue.cgRectValue
      if keyboardState.ignoringNotifications { return }

      keyboardState.keyboardRect = keyboardRect

      if !keyboardState.keyboardVisible {
        keyboardState.priorContentInset = contentInset
        keyboardState.priorScrollIndicatorInsets = scrollIndicatorInsets
        keyboardState.priorIsPagingEnabled = isPagingEnabled
      }

      keyboardState.keyboardVisible = true
      isPagingEnabled = false

      if type(of: self) == AvoidableScrollView.self {
        keyboardState.priorContentSize = contentSize
        if contentSize == .zero {
          contentSize = avoidableSvCalculateContentSizeFromSubviewFrames()
        }
      }
      if let firstResponder = self.avoidableSvFindFirstResponderBeneath(view: self) {
        contentInset = self.avoidableSvContentInsetForKeyboard()
        let viewableHeight = self.bounds.height - contentInset.top - contentInset.bottom
        UIView.animate(withDuration: TimeInterval(keyboardState.animationDuration),
                       delay: 0.01,
                       options: AnimationOptions.curveEaseInOut,
                       animations: {
                        let point = CGPoint(x: self.contentOffset.x,
                                            y: self.avoidableSvOffset(forView: firstResponder,
                                                                      withHeight: viewableHeight))
                        self.willStartAnimation()
                        self.setContentOffset(point, animated: false)
                        self.scrollIndicatorInsets = self.contentInset
                        self.layoutIfNeeded()
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
      let keyboardRect = convert(keyboardValue.cgRectValue, from: nil)
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
        if type(of: self) == AvoidableScrollView.self {
          self.contentSize = self.keyboardState.priorContentSize
        }

        self.contentInset = self.keyboardState.priorContentInset
        self.scrollIndicatorInsets = self.keyboardState.priorScrollIndicatorInsets
        self.isPagingEnabled = self.keyboardState.priorIsPagingEnabled
        self.layoutIfNeeded()
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
    if let firstResponder = avoidableSvFindFirstResponderBeneath(view: self) {
      if let view = avoidableSvFindNextInputViewAfter(view: firstResponder, beneath: self) {
        DispatchQueue.main.asyncAfter(deadline: .now()) {
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
    if let firstResponder = avoidableSvFindFirstResponderBeneath(view: self) {
      state.ignoringNotifications = true
      let visibleSpace = bounds.height - contentInset.top - contentInset.bottom
      let idealOffset = CGPoint(x: contentOffset.x,
                                y: avoidableSvOffset(forView: firstResponder,
                                                     withHeight: visibleSpace))
      UIView.animate(withDuration: TimeInterval(state.animationDuration), animations: {
        self.contentOffset = idealOffset
      }, completion: { _ in
        state.ignoringNotifications = false
      })
    }
  }

  func avoidableSvUpdateContentInset() {
    let state = keyboardState
    if state.keyboardVisible {
      contentInset = avoidableSvContentInsetForKeyboard()
    }
  }

  func avoidableSvUpdateFromContentSizeChange() {
    let state = keyboardState
    if state.keyboardVisible {
      state.priorContentSize = contentSize
      contentInset = avoidableSvContentInsetForKeyboard()
    }
  }

  func avoidableSvCalculateContentSizeFromSubviewFrames() -> CGSize {
    let wasShowingVerticalScrollIndicator = showsVerticalScrollIndicator
    let wasShowingHorizontalScrollIndicator = showsHorizontalScrollIndicator

    showsVerticalScrollIndicator = false
    showsHorizontalScrollIndicator = false

    var rect: CGRect = .zero

    for view in subviews {
      rect = rect.union(view.frame)
    }

    rect.size.height += kCalculatedContentPadding

    showsVerticalScrollIndicator = wasShowingVerticalScrollIndicator
    showsHorizontalScrollIndicator = wasShowingHorizontalScrollIndicator

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
    let priorFrame = convert(priorView.frame, from: priorView.superview)
    var candidateFrame: CGRect = .zero
    if let candidate = candidate {
      candidateFrame = convert(candidate.frame, from: candidate.superview)
    }
    var candidateHeuristic = avoidableSvNextInputViewHeuristicForView(frame: candidateFrame)

    for subview in view.subviews {
      if avoidableSvIsValidKeyCandidate(view: subview) {
        let frame = convert(subview.frame, from: view)
        let heuristic = avoidableSvNextInputViewHeuristicForView(frame: frame)

        if subview != priorView
          && ((abs(frame.minY - priorFrame.minY) < CGFloat.ulpOfOne)
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
    var newInset = contentInset
    let keyboardRect = state.keyboardRect
    newInset.bottom = keyboardRect.height - max(keyboardRect.maxY - bounds.maxY, 0)
    return newInset
  }

  func avoidableSvOffset(forView view: UIView, withHeight height: CGFloat) -> CGFloat {
    let contentSize = self.contentSize
    var offset: CGFloat = 0.0
    var subviewRect: CGRect = view.convert(view.bounds, to: self)
    var padding: CGFloat = 0.0
    var contentInset: UIEdgeInsets = .zero

    if #available(iOS 11.0, *) {
      contentInset = adjustedContentInset
    } else {
      contentInset = self.contentInset
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
        let positionRect = convert(textInput.caretRect(for: position), from: textInput as? UIView)
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
    if textField.returnKeyType == .default || textField.returnKeyType == .next && textField.delegate === self {
      textField.delegate = self
      if avoidableSvFindNextInputViewAfter(view: textField, beneath: self) != nil {
        textField.returnKeyType = .next
      } else {
        textField.returnKeyType = .done
      }
    }
  }
}
