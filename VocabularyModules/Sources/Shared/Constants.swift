//
//  Constants.swift
//  VocabularyModules
//
//  Created by Konstantinos Kolioulis on 12/7/26.
//

import Foundation
import Dependencies

public enum AppStorageKeys: String, Sendable {
  case practiceDisplayMode
  case practiceCompletedCount
  case lastVersionPromptedForReview
}

public enum InAppReviewValues {
  public static let minPathExecutionsToDisplay = 4
}
