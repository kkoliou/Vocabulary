//
//  ImportValidatorTests.swift
//  VocabularyModules
//
//  Created by Konstantinos Kolioulis on 22/3/26.
//

import CustomDump
import DependenciesTestSupport
import Foundation
import SQLiteData
import Testing
import VocabularyDB

@testable import VocabularyFeature

extension BaseSuite {
  @Suite(
    .dependencies {
      try $0.defaultDatabase.write { db in
        try db.seed {
          Vocabulary.Draft(id: UUID(-1), name: "Spanish", createdAt: Date())
          
          for i in 1...100 {
            VocabularyEntry.Draft(
              vocabularyID: UUID(-1),
              sourceWord: "word\(i)",
              translatedWord: "translation\(i)",
              isHighlighted: false
            )
          }
        }
      }
    }
  )
  
  @MainActor
  struct ImportValidatorTests {
    let validator: ImportValidator
    @Dependency(\.defaultDatabase) var database
    
    init() {
      let vocabularyLimit = 200
      let appLimit = 500
      self.validator = ImportValidator(
        vocabularyTotalEntriesLimit: vocabularyLimit,
        appTotalEntriesLimit: appLimit
      )
    }
    
    @Test func allowsImportWhenWithinVocabularyLimit() async throws {
      let entriesToImport = 50
      
      let result: () = try await validator.validateImportLimits(
        entriesCount: entriesToImport,
        vocabularyId: UUID(-1),
        database: database
      )
      
      #expect(result == ())
    }
    
    @Test func throwsVocabularyLimitExceededWhenExceeded() async throws {
      let entriesToImport = 150
      
      await #expect(throws: ImportEntriesError.self) {
        try await validator.validateImportLimits(
          entriesCount: entriesToImport,
          vocabularyId: UUID(-1),
          database: database
        )
      }
    }
    
    @Test func throwsAppLimitExceededWhenExceeded() async throws {
      let entriesToImport = 450
      
      await #expect(throws: ImportEntriesError.self) {
        try await validator.validateImportLimits(
          entriesCount: entriesToImport,
          vocabularyId: UUID(-1),
          database: database
        )
      }
    }
    
    @Test func vocabularyLimitChecksExactCount() async throws {
      let currentCount = try await database.read { db in
        try VocabularyEntry
          .where { $0.vocabularyID == UUID(-1) }
          .fetchCount(db)
      }
      
      let availableSlots = 200 - currentCount
      let entriesToImport = availableSlots + 1
      
      do {
        try await validator.validateImportLimits(
          entriesCount: entriesToImport,
          vocabularyId: UUID(-1),
          database: database
        )
        Issue.record("Expected vocabularyLimitExceeded error")
      } catch let error as ImportEntriesError {
        guard case .vocabularyLimitExceeded(let limitChecks) = error else {
          Issue.record("Wrong error type")
          return
        }
        #expect(limitChecks.limit == 200)
        #expect(limitChecks.availableSlots == availableSlots)
      }
    }
    
    @Test func allowsImportEqualToExactLimit() async throws {
      let currentCount = try await database.read { db in
        try VocabularyEntry
          .where { $0.vocabularyID == UUID(-1) }
          .fetchCount(db)
      }
      
      let availableSlots = 200 - currentCount
      
      let result: () = try await validator.validateImportLimits(
        entriesCount: availableSlots,
        vocabularyId: UUID(-1),
        database: database
      )
      
      #expect(result == ())
    }
    
    @Test func allowsZeroEntries() async throws {
      let result: () = try await validator.validateImportLimits(
        entriesCount: 0,
        vocabularyId: UUID(-1),
        database: database
      )
      
      #expect(result == ())
    }
  }
}
