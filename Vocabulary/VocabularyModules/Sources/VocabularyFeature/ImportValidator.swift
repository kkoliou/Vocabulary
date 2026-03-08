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
  func validateImportLimits(
    entriesCount: Int,
    vocabularyId: UUID,
    database: DatabaseReader
  ) async throws {
    let counts = try await database.read { db in
      let vocabularyEntryCount = try VocabularyEntry
        .where { $0.vocabularyID == vocabularyId }
        .fetchCount(db)
      let totalEntryCount = try VocabularyEntry
        .fetchCount(db)
      return (vocabularyEntryCount, totalEntryCount)
    }
    
    let vocabularyEntryCount = counts.0
    let totalEntryCount = counts.1
    
    let vocabularyAvailableSlots = 5000 - vocabularyEntryCount
    let appAvailableSlots = 50000 - totalEntryCount
    
    if entriesCount > vocabularyAvailableSlots && entriesCount > appAvailableSlots {
      throw ImportEntriesError.notEnoughCapacity(
        entriesCount: entriesCount,
        vocabularyAvailable: vocabularyAvailableSlots,
        appAvailable: appAvailableSlots
      )
    }
    
    if entriesCount > vocabularyAvailableSlots {
      throw ImportEntriesError.vocabularyLimitExceeded(5000, availableSlots: vocabularyAvailableSlots)
    }
    
    if entriesCount > appAvailableSlots {
      throw ImportEntriesError.appLimitExceeded(50000, availableSlots: appAvailableSlots)
    }
  }
}

enum ImportEntriesError: Error {
  case vocabularyLimitExceeded(Int, availableSlots: Int)
  case appLimitExceeded(Int, availableSlots: Int)
  case notEnoughCapacity(entriesCount: Int, vocabularyAvailable: Int, appAvailable: Int)
}
