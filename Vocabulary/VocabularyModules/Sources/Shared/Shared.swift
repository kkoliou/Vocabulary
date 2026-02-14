// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

public extension Bundle {
  static var sharedModule: Bundle { Bundle.module }
}

public struct Strings {
  public static func localized(_ key: StaticString) -> LocalizedStringResource {
    return LocalizedStringResource(key, defaultValue: "", bundle: .sharedModule)
  }
}
