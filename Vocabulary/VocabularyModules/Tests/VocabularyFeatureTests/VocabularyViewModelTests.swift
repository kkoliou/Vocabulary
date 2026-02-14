//
//  VocabularyViewModelTests.swift
//  VocabularyModules
//
//  Created by Konstantinos Kolioulis on 14/2/26.
//

import CustomDump
import DependenciesTestSupport
import Foundation
import SQLiteData
import Testing
import VocabularyDB
import Shared

@testable import VocabularyFeature

extension BaseSuite {
  @Suite(
    .dependencies {
      try $0.defaultDatabase.write { db in
        try db.seed {
          Vocabulary.Draft(id: UUID(-1), name: "Spanish", createdAt: Date(timeIntervalSince1970: 1000))
          Vocabulary.Draft(id: UUID(-2), name: "French", createdAt: Date(timeIntervalSince1970: 2000))
          
          // Spanish vocabulary entries
          VocabularyEntry.Draft(
            id: UUID(-10),
            vocabularyID: UUID(-1),
            sourceWord: "hello",
            translatedWord: "hola",
            isHighlighted: false
          )
          VocabularyEntry.Draft(
            id: UUID(-11),
            vocabularyID: UUID(-1),
            sourceWord: "goodbye",
            translatedWord: "adiós",
            isHighlighted: true
          )
          VocabularyEntry.Draft(
            id: UUID(-12),
            vocabularyID: UUID(-1),
            sourceWord: "thank you",
            translatedWord: "gracias",
            isHighlighted: false
          )
          VocabularyEntry.Draft(
            id: UUID(-13),
            vocabularyID: UUID(-1),
            sourceWord: "please",
            translatedWord: "por favor",
            isHighlighted: true
          )
          
          // French vocabulary entries
          VocabularyEntry.Draft(
            id: UUID(-20),
            vocabularyID: UUID(-2),
            sourceWord: "hello",
            translatedWord: "bonjour",
            isHighlighted: false
          )
          VocabularyEntry.Draft(
            id: UUID(-21),
            vocabularyID: UUID(-2),
            sourceWord: "goodbye",
            translatedWord: "au revoir",
            isHighlighted: false
          )
        }
      }
    }
  )
  
  @MainActor
  struct VocabularyViewModelTests {
    let model: VocabularyViewModel
    let vocabulary: Vocabulary
    @Dependency(\.defaultDatabase) var database

    init() async throws {
      vocabulary = try await #require(
        _database.wrappedValue.read { db in
          try Vocabulary.find(UUID(-1)).fetchOne(db)
        }
      )
      model = VocabularyViewModel(vocabulary: vocabulary)
      await model.doInit()
    }

    @Test func initialState() async throws {
      #expect(model.isAddEntryPresented == false)
      #expect(model.isAddFilePresented == false)
      #expect(model.vocabulary.id == UUID(-1))
      #expect(model.entries.count == 4)
    }

    @Test func loadEntriesForSpecificVocabulary() async throws {
      // Verify only Spanish entries are loaded
      #expect(model.entries.count == 4)
      #expect(model.entries.allSatisfy { $0.vocabularyID == UUID(-1) })
      
      // Verify French entries are not included
      #expect(model.entries.contains { $0.sourceWord == "bonjour" } == false)
    }

    @Test func addEntryTappedPresentsSheet() async throws {
      #expect(model.isAddEntryPresented == false)
      
      model.addEntryTapped()
      
      #expect(model.isAddEntryPresented == true)
    }

    @Test func addFileTappedPresentsSheet() async throws {
      #expect(model.isAddFilePresented == false)
      
      model.addFileTapped()
      
      #expect(model.isAddFilePresented == true)
    }

    @Test func addToHighlights() async throws {
      let entry = model.entries[0] // "hello" with isHighlighted = false
      #expect(entry.isHighlighted == false)
      
      await expectDifference(model.entries) {
        model.addToHighlightsTapped(for: entry)
        try await model.$entries.load()
      } changes: { entries in
        entries[0].isHighlighted = true
      }
      
      // Verify database was updated
      let updatedEntry = try await database.read { db in
        try VocabularyEntry.find(UUID(-10)).fetchOne(db)
      }
      
      #expect(updatedEntry?.isHighlighted == true)
    }

    @Test func removeFromHighlights() async throws {
      let entry = model.entries[1] // "goodbye" with isHighlighted = true
      #expect(entry.isHighlighted == true)
      
      await expectDifference(model.entries) {
        model.removeFromHighlightsTapped(for: entry)
        try await model.$entries.load()
      } changes: { entries in
        entries[1].isHighlighted = false
      }
      
      // Verify database was updated
      let updatedEntry = try await database.read { db in
        try VocabularyEntry.find(UUID(-11)).fetchOne(db)
      }
      
      #expect(updatedEntry?.isHighlighted == false)
    }

    @Test func toggleHighlightMultipleTimes() async throws {
      let entry = model.entries[0]
      
      // Add to highlights
      await expectDifference(model.entries) {
        model.addToHighlightsTapped(for: entry)
        try await model.$entries.load()
      } changes: { entries in
        entries[0].isHighlighted = true
      }
      
      // Remove from highlights
      await expectDifference(model.entries) {
        model.removeFromHighlightsTapped(for: model.entries[0])
        try await model.$entries.load()
      } changes: { entries in
        entries[0].isHighlighted = false
      }
      
      // Add to highlights again
      await expectDifference(model.entries) {
        model.addToHighlightsTapped(for: model.entries[0])
        try await model.$entries.load()
      } changes: { entries in
        entries[0].isHighlighted = true
      }
    }

    @Test func highlightMultipleEntries() async throws {
      let firstEntry = model.entries[0]
      let thirdEntry = model.entries[2]
      
      #expect(firstEntry.isHighlighted == false)
      #expect(thirdEntry.isHighlighted == false)
      
      // Highlight first entry
      model.addToHighlightsTapped(for: firstEntry)
      try await model.$entries.load()
      
      // Highlight third entry
      model.addToHighlightsTapped(for: model.entries[2])
      try await model.$entries.load()
      
      #expect(model.entries[0].isHighlighted == true)
      #expect(model.entries[2].isHighlighted == true)
      
      // Verify database state
      let highlightedCount = try await database.read { db in
        try VocabularyEntry
          .where { $0.vocabularyID == UUID(-1) && $0.isHighlighted == true }
          .fetchCount(db)
      }
      
      #expect(highlightedCount == 4) // 2 originally highlighted + 2 newly highlighted
    }

    @Test func highlightDoesNotAffectOtherVocabularies() async throws {
      let entry = model.entries[0]
      
      model.addToHighlightsTapped(for: entry)
      try await model.$entries.load()
      
      // Verify French vocabulary entries are unchanged
      let frenchEntries = try await database.read { db in
        try VocabularyEntry
          .where { $0.vocabularyID == UUID(-2) }
          .fetchAll(db)
      }
      
      #expect(frenchEntries.allSatisfy { $0.isHighlighted == false })
    }

    @Test func loadEntriesAfterExternalAddition() async throws {
      // Add entry directly to database
      try await database.write { db in
        try VocabularyEntry.insert {
          VocabularyEntry.Draft(
            id: UUID(0),
            vocabularyID: UUID(-1),
            sourceWord: "water",
            translatedWord: "agua",
            isHighlighted: false
          )
        }
        .execute(db)
      }
      
      // Reload entries
      try await model.$entries.load()
      
      #expect(model.entries.count == 5)
      #expect(model.entries.contains { $0.sourceWord == "water" })
    }

    @Test func emptyVocabularyState() async throws {
      // Create empty vocabulary
      try await database.write { db in
        try Vocabulary.insert {
          Vocabulary.Draft(id: UUID(0), name: "Empty", createdAt: Date())
        }
        .execute(db)
      }
      
      let emptyVocab = try await database.read { db in
        try Vocabulary.find(UUID(0)).fetchOne(db)
      }
      
      let emptyModel = VocabularyViewModel(vocabulary: emptyVocab!)
      await emptyModel.doInit()
      
      #expect(emptyModel.entries.isEmpty)
    }

    @Test func filterEntriesByHighlightStatus() async throws {
      let highlighted = model.entries.filter { $0.isHighlighted }
      let notHighlighted = model.entries.filter { !$0.isHighlighted }
      
      #expect(highlighted.count == 2)
      #expect(notHighlighted.count == 2)
      
      #expect(highlighted.map(\.sourceWord).sorted() == ["goodbye", "please"])
      #expect(notHighlighted.map(\.sourceWord).sorted() == ["hello", "thank you"])
    }

    @Test func highlightEntryThatIsAlreadyHighlighted() async throws {
      let entry = model.entries[1] // "goodbye" already highlighted
      #expect(entry.isHighlighted == true)
      
      model.addToHighlightsTapped(for: entry)
      try await model.$entries.load()
      
      // Should still be highlighted
      #expect(model.entries[1].isHighlighted == true)
    }

    @Test func unhighlightEntryThatIsNotHighlighted() async throws {
      let entry = model.entries[0] // "hello" not highlighted
      #expect(entry.isHighlighted == false)
      
      model.removeFromHighlightsTapped(for: entry)
      try await model.$entries.load()
      
      // Should still not be highlighted
      #expect(model.entries[0].isHighlighted == false)
    }

    @Test func multipleVocabularyViewModelsIndependent() async throws {
      // Create model for French vocabulary
      let frenchVocab = try await #require(
        database.read { db in
          try Vocabulary.find(UUID(-2)).fetchOne(db)
        }
      )
      let frenchModel = VocabularyViewModel(vocabulary: frenchVocab)
      await frenchModel.doInit()
      
      #expect(frenchModel.entries.count == 2)
      #expect(model.entries.count == 4)
      
      // Modify Spanish vocabulary
      model.addToHighlightsTapped(for: model.entries[0])
      try await model.$entries.load()
      
      // French vocabulary should be unaffected
      #expect(frenchModel.entries.allSatisfy { !$0.isHighlighted })
    }

    @Test func presentationStateChanges() async throws {
      model.addEntryTapped()
      #expect(model.isAddEntryPresented == true)
      
      // Simulate dismissal
      model.isAddEntryPresented = false
      
      model.addFileTapped()
      #expect(model.isAddFilePresented == true)
      
      // Both can be triggered separately
      model.addEntryTapped()
      #expect(model.isAddEntryPresented == true)
      #expect(model.isAddFilePresented == true)
    }

    @Test func highlightAllEntries() async throws {
      for entry in model.entries {
        model.addToHighlightsTapped(for: entry)
      }
      try await model.$entries.load()
      
      #expect(model.entries.allSatisfy { $0.isHighlighted })
      
      // Verify database state
      let allHighlighted = try await database.read { db in
        try VocabularyEntry
          .where { $0.vocabularyID == UUID(-1) }
          .fetchAll(db)
          .allSatisfy { $0.isHighlighted }
      }
      
      #expect(allHighlighted)
    }

    @Test func unhighlightAllEntries() async throws {
      for entry in model.entries {
        model.removeFromHighlightsTapped(for: entry)
      }
      try await model.$entries.load()
      
      #expect(model.entries.allSatisfy { !$0.isHighlighted })
      
      // Verify database state
      let noneHighlighted = try await database.read { db in
        try VocabularyEntry
          .where { $0.vocabularyID == UUID(-1) }
          .fetchAll(db)
          .allSatisfy { !$0.isHighlighted }
      }
      
      #expect(noneHighlighted)
    }

    @Test func vocabularyPropertyIsImmutable() async throws {
      let originalVocabId = model.vocabulary.id
      
      // Perform various operations
      model.addEntryTapped()
      model.addToHighlightsTapped(for: model.entries[0])
      try await model.$entries.load()
      
      // Vocabulary should remain the same
      #expect(model.vocabulary.id == originalVocabId)
    }
  }
}
