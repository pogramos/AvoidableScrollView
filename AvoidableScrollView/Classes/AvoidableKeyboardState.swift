//
//  AvoidableKeyboardState.swift
//  MobileBanking
//
//  Created by Guilherme Ramos on 28/11/18.
//  Copyright © 2018 BS2. All rights reserved.
//

import Foundation

class AvoidableKeyboardState {
  var priorContentInset: UIEdgeInsets = .zero
  var priorIsPagingEnabled: Bool = false
  var priorContentSize: CGSize = .zero
  var priorScrollIndicatorInsets: UIEdgeInsets = .zero

  var keyboardRect: CGRect = .zero
  var keyboardVisible: Bool = false
  var animationDuration: CGFloat = 0.5
  var animationInProgress: Bool = false
  var animationCurve: UIViewAnimationCurve = .easeInOut
  var ignoringNotifications: Bool = false
}
