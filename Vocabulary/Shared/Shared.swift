// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import UIKit

public extension Bundle {
  static var currentAppVersion: String? {
    return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
  }
}

public struct Strings {
  public static func localized(_ key: StaticString) -> LocalizedStringResource {
    return LocalizedStringResource(key, defaultValue: "", bundle: .main)
  }
}

public struct Utilities {
  @MainActor
  public static func triggerLightHaptic() {
    let generator = UIImpactFeedbackGenerator(style: .light)
    generator.impactOccurred()
  }
}
