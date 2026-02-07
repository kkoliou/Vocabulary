//
//  SwiftUIView.swift
//  Shared
//
//  Created by Konstantinos Kolioulis on 7/2/26.
//

import SwiftUI

public extension View {
  @ViewBuilder
  func glassButtonIfAvailable() -> some View {
    if #available(iOS 26.0, *) {
      self
        .buttonStyle(.glassProminent)
    } else {
      self
    }
  }
}
