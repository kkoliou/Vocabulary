import Foundation

public extension String {
  func trimmed() -> String {
    trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
