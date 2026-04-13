//
//  ImportValidator.swift
//  VocabularyModules
//
//  Created by Konstantinos Kolioulis on 8/3/26.
//

import Foundation
import SQLiteData
import VocabularyDB

@MainActor
struct ImportValidator: ImportValidatorProtocol {
  
  private let vocabularyTotalEntriesLimit: Int
  private let appTotalEntriesLimit: Int
  
  init(
    vocabularyTotalEntriesLimit: Int = ImportValidatorConstants.vocabularyTotalEntriesLimit,
    appTotalEntriesLimit: Int = ImportValidatorConstants.appTotalEntriesLimit
  ) {
    self.vocabularyTotalEntriesLimit = vocabularyTotalEntriesLimit
    self.appTotalEntriesLimit = appTotalEntriesLimit
  }
  
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
        .where { $0.vocabularyID.eq(vocabularyId) }
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

@MainActor protocol ImportValidatorProtocol {
  func validateImportLimits(
    entriesCount: Int,
    vocabularyId: UUID,
    database: DatabaseReader
  ) async throws
}

struct ImportValidatorConstants {
  static let vocabularyTotalEntriesLimit: Int = 5000
  static let appTotalEntriesLimit: Int = 50000
}

class ImportValidatorMock: ImportValidatorProtocol {
  var count: Int = -1
  func validateImportLimits(
    entriesCount: Int,
    vocabularyId: UUID,
    database: any DatabaseReader
  ) async throws {
    count += 1
    if count % 2 == 0 {
      throw ImportEntriesError.appLimitExceeded(.init(limit: 50000, availableSlots: 1))
    } else {
      throw ImportEntriesError.vocabularyLimitExceeded(.init(limit: 5000, availableSlots: 50))
    }
  }
}
