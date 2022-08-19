//
//  AvoidableTableView.swift
//  Example
//
//  Created by Guilherme Ramos on 11/12/18.
//  Copyright © 2018 Guilherme Ramos. All rights reserved.
//

import UIKit
import ObjectiveC

final class AvoidableTableView: UITableView {

  lazy var avoidableScrollViewKit: AvoidableScrollViewKit = self.makeAvoidableScrollViewKit()
  private func makeAvoidableScrollViewKit() -> AvoidableScrollViewKit {
    return AvoidableScrollViewKit(with: self, block: scrollToActiveTextField)
  }

  override var frame: CGRect {
    didSet {
      avoidableScrollViewKit.avoidableSvUpdateContentInset()
    }
  }

  override var contentSize: CGSize {
    didSet {
      avoidableScrollViewKit.avoidableSvUpdateFromContentSizeChange()
    }
  }

  private func setup() {
    avoidableScrollViewKit.register()
  }

  override init(frame: CGRect, style: UITableView.Style) {
    super.init(frame: frame, style: style)
    setup()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    setup()
  }

  func contentSizeToFit() {
    contentSize = avoidableScrollViewKit.avoidableSvCalculateContentSizeFromSubviewFrames()
  }

  func focusNextTextField() -> Bool {
    return avoidableScrollViewKit.avoidableSvFocusNextTextField()
  }

  @objc func scrollToActiveTextField() {
    avoidableScrollViewKit.avoidableSvScrollToActiveFirstResponder()
  }

  // MARK: - Events

  override func willMove(toSuperview newSuperview: UIView?) {
    super.willMove(toSuperview: newSuperview)
    if newSuperview == nil {
      avoidableScrollViewKit.cancelPreviousRequest()
    }
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    avoidableScrollViewKit.avoidableSvFindFirstResponderBeneath(view: self)?.resignFirstResponder()
    super.touchesEnded(touches, with: event)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    avoidableScrollViewKit.cancelPreviousRequest()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      self.avoidableScrollViewKit.avoidableSvAssignTextDelegateForViews(beneath: self)
    }
  }
}

extension AvoidableTableView: UITextFieldDelegate, UITextViewDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if !focusNextTextField() {
      textField.resignFirstResponder()
    }
    return true
  }
}
