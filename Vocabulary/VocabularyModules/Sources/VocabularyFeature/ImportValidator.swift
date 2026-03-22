//
//  ImportValidator.swift
//  VocabularyModules
//
//  Created by Konstantinos Kolioulis on 8/3/26.
//

import Foundation
import SQLiteData
import VocabularyDB

struct ImportValidator {
  private let vocabularyTotalEntriesLimit: Int = 5000
  private let appTotalEntriesLimit: Int = 50000
  
  func validateImportLimits(
    entriesCount: Int,
    vocabularyId: UUID,
    database: DatabaseReader
  ) async throws {
    struct Counts {
      let vocabularyEntryCount: Int
      let totalEntryCount: Int
    }
    let counts = try await database.read { db in
      let vocabularyEntryCount = try VocabularyEntry
        .where { $0.vocabularyID == vocabularyId }
        .fetchCount(db)
      let totalEntryCount = try VocabularyEntry
        .fetchCount(db)
      return Counts(
        vocabularyEntryCount: vocabularyEntryCount,
        totalEntryCount: totalEntryCount
      )
    }
    
    let vocabularyEntryCount = counts.vocabularyEntryCount
    let totalEntryCount = counts.totalEntryCount
    
    let vocabularyAvailableSlots = vocabularyTotalEntriesLimit - vocabularyEntryCount
    
    if entriesCount > vocabularyAvailableSlots {
      throw ImportEntriesError.vocabularyLimitExceeded(
        .init(limit: vocabularyTotalEntriesLimit, availableSlots: vocabularyAvailableSlots)
      )
    }
    
    let appAvailableSlots = appTotalEntriesLimit - totalEntryCount
    
    if entriesCount > appAvailableSlots {
      throw ImportEntriesError.appLimitExceeded(
        .init(limit: appTotalEntriesLimit, availableSlots: appAvailableSlots)
      )
    }
  }
}

enum ImportEntriesError: Error {
  case vocabularyLimitExceeded(LimitChecks)
  case appLimitExceeded(LimitChecks)
}

struct LimitChecks {
  let limit: Int
  let availableSlots: Int
}
