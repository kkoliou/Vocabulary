//
//  PracticeDisplayMode.swift
//  Shared
//

import Foundation
import SwiftUI

public enum PracticeDisplayMode: String, CaseIterable, Identifiable, Sendable {
  case cards
  case buttons

  public static let appStorageKey = "practiceDisplayMode"

  public var id: String { rawValue }

  public var title: LocalizedStringResource {
    switch self {
    case .cards:
      Strings.localized("Cards")
    case .buttons:
      Strings.localized("Buttons")
    }
  }

  public var useCardsStackMode: Bool {
    self == .cards
  }
}
