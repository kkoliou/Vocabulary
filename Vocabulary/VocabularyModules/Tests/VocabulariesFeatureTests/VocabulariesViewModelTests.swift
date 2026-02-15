//
//  VocabulariesViewModelTests.swift
//  VocabularyModules
//
//  Created by Konstantinos Kolioulis on 14/2/26.
//

import CustomDump
import Foundation
import SQLiteData
import Testing
import SQLiteData
import VocabularyDB
import Shared
import DependenciesTestSupport

@testable import VocabulariesFeature

extension BaseSuite {
  @Suite(
    .dependencies {
      try $0.defaultDatabase.write { db in
        try db.seed {
          Vocabulary.Draft(id: UUID(-1), name: "Spanish", createdAt: Date(timeIntervalSince1970: 1000))
          Vocabulary.Draft(id: UUID(-2), name: "French", createdAt: Date(timeIntervalSince1970: 2000))
          Vocabulary.Draft(id: UUID(-3), name: "German", createdAt: Date(timeIntervalSince1970: 3000))
          Vocabulary.Draft(id: UUID(-4), name: "Italian", createdAt: Date(timeIntervalSince1970: 4000))
        }
      }
    }
  )
  
  @MainActor
  struct VocabulariesViewModelTests {
    let model: VocabulariesViewModel
    @Dependency(\.defaultDatabase) var database

    init() async throws {
      model = VocabulariesViewModel()
      await model.doInit()
    }

    @Test func vocabulariesAreOrderedByCreatedAt() async throws {
      #expect(model.vocabularies.count == 4)
      #expect(model.vocabularies[0].name == "Spanish")
      #expect(model.vocabularies[1].name == "French")
      #expect(model.vocabularies[2].name == "German")
      #expect(model.vocabularies[3].name == "Italian")
      
      // Verify order is by createdAt ascending
      for i in 0..<(model.vocabularies.count - 1) {
        #expect(model.vocabularies[i].createdAt <= model.vocabularies[i + 1].createdAt)
      }
    }

    @Test func addVocabularyTappedPresentsSheet() async throws {
      #expect(model.addVocabIsPresented == false)
      
      model.addVocabularyTapped()
      
      #expect(model.addVocabIsPresented == true)
    }

    @Test func deleteVocabularyAtFirstIndex() async throws {
      await expectDifference(model.vocabularies) {
        await model.deleteVocabularies(at: [0])
        try await model.$vocabularies.load()
      } changes: { vocabularies in
        vocabularies.remove(at: 0)
      }
      
      // Verify it was deleted from database
      let count = try await database.read { db in
        try Vocabulary.fetchCount(db)
      }
      #expect(count == 3)
      
      let exists = try await database.read { db in
        try Vocabulary.find(UUID(-1)).fetchOne(db) != nil
      }
      #expect(exists == false)
    }

    @Test func deleteVocabularyAtLastIndex() async throws {
      await expectDifference(model.vocabularies) {
        await model.deleteVocabularies(at: [3])
        try await model.$vocabularies.load()
      } changes: { vocabularies in
        vocabularies.remove(at: 3)
      }
      
      let exists = try await database.read { db in
        try Vocabulary.find(UUID(-4)).fetchOne(db) != nil
      }
      #expect(exists == false)
    }

    @Test func deleteMultipleVocabularies() async throws {
      await expectDifference(model.vocabularies) {
        await model.deleteVocabularies(at: [0, 2])
        try await model.$vocabularies.load()
      } changes: { vocabularies in
        vocabularies.remove(at: 2) // Remove in reverse order to maintain indices
        vocabularies.remove(at: 0)
      }
      
      // Verify both were deleted
      let count = try await database.read { db in
        try Vocabulary.fetchCount(db)
      }
      #expect(count == 2)
      
      let remaining = try await database.read { db in
        try Vocabulary.fetchAll(db)
      }
      #expect(remaining.map(\.name) == ["French", "Italian"])
    }

    @Test func deleteAllVocabularies() async throws {
      await expectDifference(model.vocabularies) {
        await model.deleteVocabularies(at: [0, 1, 2, 3])
        try await model.$vocabularies.load()
      } changes: { vocabularies in
        vocabularies.removeAll()
      }
      
      let count = try await database.read { db in
        try Vocabulary.fetchCount(db)
      }
      #expect(count == 0)
    }

    @Test func deleteVocabularyInMiddle() async throws {
      await expectDifference(model.vocabularies) {
        await model.deleteVocabularies(at: [1])
        try await model.$vocabularies.load()
      } changes: { vocabularies in
        vocabularies.remove(at: 1)
      }
      
      let remaining = try await database.read { db in
        try Vocabulary.fetchAll(db).map(\.name)
      }
      #expect(remaining == ["Spanish", "German", "Italian"])
    }

    @Test func emptyStateAfterInitialization() async throws {
      // Create a fresh database with no vocabularies
      try await database.write { db in
        try Vocabulary.delete().execute(db)
      }
      
      let emptyModel = VocabulariesViewModel()
      
      #expect(emptyModel.vocabularies.isEmpty)
    }

    @Test func reloadAfterExternalChange() async throws {
      // Add a vocabulary directly to the database
      try await database.write { db in
        try Vocabulary.insert {
          Vocabulary.Draft(id: UUID(0), name: "Portuguese", createdAt: Date())
        }
        .execute(db)
      }
      
      // Reload the model
      try await model.$vocabularies.load()
      
      #expect(model.vocabularies.count == 5)
      #expect(model.vocabularies.last?.name == "Portuguese")
    }

    @Test func deleteNonConsecutiveIndices() async throws {
      await expectDifference(model.vocabularies) {
        await model.deleteVocabularies(at: [0, 3])
        try await model.$vocabularies.load()
      } changes: { vocabularies in
        vocabularies.remove(at: 3)
        vocabularies.remove(at: 0)
      }
      
      let remaining = try await database.read { db in
        try Vocabulary.fetchAll(db).map(\.name)
      }
      #expect(remaining == ["French", "German"])
    }

    @Test func multipleAddVocabularyTaps() async throws {
      model.addVocabularyTapped()
      #expect(model.addVocabIsPresented == true)
      
      // Simulate dismissal
      model.addVocabIsPresented = false
      
      model.addVocabularyTapped()
      #expect(model.addVocabIsPresented == true)
    }
  }
}
