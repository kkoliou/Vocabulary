import Foundation
import Dependencies

public enum AppStorageKeys: String, Sendable {
  case practiceDisplayMode
  case practiceCompletedCount
  case lastVersionPromptedForReview
  case lastDatePromptedForReview
}

public enum InAppReviewValues {
  public static let minPathExecutionsToDisplay = 4
  public static let reviewWindow: CGFloat = 365/3
}
