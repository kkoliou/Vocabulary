import Foundation
import Dependencies

extension DependencyValues {
  public var currentAppVersion: String? {
    get { self[DefaultCurrentAppVersionKey.self] }
    set { self[DefaultCurrentAppVersionKey.self] = newValue }
  }
}

private enum DefaultCurrentAppVersionKey: DependencyKey {
  static var liveValue: String? { Bundle.currentAppVersion }
  static var testValue: String? { Bundle.currentAppVersion }
}
