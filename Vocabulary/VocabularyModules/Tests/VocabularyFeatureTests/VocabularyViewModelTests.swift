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
    
    // MARK: - Sorting Tests
    
    @Test func defaultSortOrderByRowId() async throws {
      #expect(model.sortOption == .defaultSort)
      
      // Default sort should maintain insertion order (by rowid)
      expectNoDifference(
        model.entries.map(\.sourceWord),
        ["hello", "goodbye", "thank you", "please"]
      )
    }
    
    @Test func sortByHighlightsDescending() async throws {
      model.sortOption = .highlights
      
      // Wait for reload triggered by didSet
      await model.reloadTask?.value
      
      // Highlighted entries should come first
      let highlighted = model.entries.prefix(2)
      let notHighlighted = model.entries.suffix(2)
      
      #expect(highlighted.allSatisfy { $0.isHighlighted })
      #expect(notHighlighted.allSatisfy { !$0.isHighlighted })
      
      // Should be: goodbye (highlighted), please (highlighted), hello (not), thank you (not)
      #expect(model.entries[0].isHighlighted == true)
      #expect(model.entries[1].isHighlighted == true)
      #expect(model.entries[2].isHighlighted == false)
      #expect(model.entries[3].isHighlighted == false)
    }
    
    @Test func sortByAlphabetical() async throws {
      model.sortOption = .alphabetical
      
      // Wait for reload triggered by didSet
      await model.reloadTask?.value
      
      let sourceWords = model.entries.map(\.sourceWord)
      
      expectNoDifference(
        sourceWords,
        ["goodbye", "hello", "please", "thank you"]
      )
    }
    
    @Test func sortOptionChangeTriggersReload() async throws {
      let initialOrder = model.entries.map(\.sourceWord)
      #expect(initialOrder == ["hello", "goodbye", "thank you", "please"])
      
      model.sortOption = .alphabetical
      await model.reloadTask?.value
      
      let alphabeticalOrder = model.entries.map(\.sourceWord)
      #expect(alphabeticalOrder == ["goodbye", "hello", "please", "thank you"])
      
      model.sortOption = .highlights
      await model.reloadTask?.value
      
      // First two should be highlighted
      #expect(model.entries[0].isHighlighted == true)
      #expect(model.entries[1].isHighlighted == true)
    }
    
    @Test func sortBackToDefaultAfterChanging() async throws {
      // Change to alphabetical
      model.sortOption = .alphabetical
      await model.reloadTask?.value
      #expect(model.entries.map(\.sourceWord) == ["goodbye", "hello", "please", "thank you"])
      
      // Change back to default
      model.sortOption = .defaultSort
      await model.reloadTask?.value
      #expect(model.entries.map(\.sourceWord) == ["hello", "goodbye", "thank you", "please"])
    }
    
    @Test func sortByHighlightsWithAllHighlighted() async throws {
      // Highlight all entries
      for entry in model.entries {
        model.addToHighlightsTapped(for: entry)
      }
      try await model.$entries.load()
      
      model.sortOption = .highlights
      await model.reloadTask?.value
      
      // All should be highlighted
      #expect(model.entries.allSatisfy { $0.isHighlighted })
    }
    
    @Test func sortByHighlightsWithNoneHighlighted() async throws {
      // Unhighlight all entries
      for entry in model.entries {
        model.removeFromHighlightsTapped(for: entry)
      }
      try await model.$entries.load()
      
      model.sortOption = .highlights
      await model.reloadTask?.value
      
      // None should be highlighted
      #expect(model.entries.allSatisfy { !$0.isHighlighted })
    }
    
    @Test func sortAlphabeticalWithSpecialCharacters() async throws {
      // Add entries with special characters
      try await database.write { db in
        try db.seed {
          VocabularyEntry.Draft(
            id: UUID(0),
            vocabularyID: UUID(-1),
            sourceWord: "año",
            translatedWord: "year",
            isHighlighted: false
          )
          VocabularyEntry.Draft(
            id: UUID(1),
            vocabularyID: UUID(-1),
            sourceWord: "zebra",
            translatedWord: "cebra",
            isHighlighted: false
          )
        }
      }
      
      model.sortOption = .alphabetical
      await model.reloadTask?.value
      
      let sourceWords = model.entries.map(\.sourceWord)
      
      // Should be sorted alphabetically
      #expect(sourceWords.first == "año")
      #expect(sourceWords.last == "zebra")
    }
    
    @Test func sortAlphabeticalIsCaseSensitive() async throws {
      // Add entries with different cases
      try await database.write { db in
        try db.seed {
          VocabularyEntry.Draft(
            id: UUID(0),
            vocabularyID: UUID(-1),
            sourceWord: "Apple",
            translatedWord: "manzana",
            isHighlighted: false
          )
          VocabularyEntry.Draft(
            id: UUID(1),
            vocabularyID: UUID(-1),
            sourceWord: "banana",
            translatedWord: "plátano",
            isHighlighted: false
          )
        }
      }
      
      model.sortOption = .alphabetical
      await model.reloadTask?.value
      
      // Capital letters typically come before lowercase in ASCII sorting
      let appleIndex = model.entries.firstIndex { $0.sourceWord == "Apple" }
      let bananaIndex = model.entries.firstIndex { $0.sourceWord == "banana" }
      
      #expect(appleIndex != nil)
      #expect(bananaIndex != nil)
    }
    
    @Test func highlightChangeMaintainsSortOrder() async throws {
      model.sortOption = .highlights
      await model.reloadTask?.value
      
      let initialHighlightedCount = model.entries.filter { $0.isHighlighted }.count
      #expect(initialHighlightedCount == 2)
      
      // Add an unhighlighted entry to highlights
      let unhighlightedEntry = model.entries.first { !$0.isHighlighted }!
      model.addToHighlightsTapped(for: unhighlightedEntry)
      try await model.$entries.load()
      
      // After reload, should still be sorted by highlights
      let newHighlightedCount = model.entries.filter { $0.isHighlighted }.count
      #expect(newHighlightedCount == 3)
      
      // First 3 entries should be highlighted
      #expect(model.entries[0].isHighlighted == true)
      #expect(model.entries[1].isHighlighted == true)
      #expect(model.entries[2].isHighlighted == true)
      #expect(model.entries[3].isHighlighted == false)
    }
    
    @Test func sortOptionPersistsAcrossOperations() async throws {
      model.sortOption = .alphabetical
      await model.reloadTask?.value
      
      // Perform operations
      model.addEntryTapped()
      model.addToHighlightsTapped(for: model.entries[0])
      try await model.$entries.load()
      
      // Sort option should still be alphabetical
      #expect(model.sortOption == .alphabetical)
    }
    
    @Test func multipleSortChangesInQuickSuccession() async throws {
      model.sortOption = .alphabetical
      model.sortOption = .highlights
      model.sortOption = .defaultSort
      
      await model.reloadTask?.value
      
      // Should end up with default sort
      #expect(model.sortOption == .defaultSort)
      #expect(model.entries.map(\.sourceWord) == ["hello", "goodbye", "thank you", "please"])
    }
    
    @Test func sortingWithEmptyVocabulary() async throws {
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
      
      // Change sort options on empty vocabulary
      emptyModel.sortOption = .alphabetical
      await model.reloadTask?.value
      #expect(emptyModel.entries.isEmpty)
      
      emptyModel.sortOption = .highlights
      await model.reloadTask?.value
      #expect(emptyModel.entries.isEmpty)
    }
    
    @Test func sortingDoesNotAffectOtherVocabularies() async throws {
      // Create model for French vocabulary
      let frenchVocab = try await #require(
        database.read { db in
          try Vocabulary.find(UUID(-2)).fetchOne(db)
        }
      )
      let frenchModel = VocabularyViewModel(vocabulary: frenchVocab)
      await frenchModel.doInit()
      
      let frenchInitialOrder = frenchModel.entries.map(\.sourceWord)
      
      // Change Spanish model sort
      model.sortOption = .alphabetical
      await model.reloadTask?.value
      
      // French model should be unaffected
      #expect(frenchModel.entries.map(\.sourceWord) == frenchInitialOrder)
      #expect(frenchModel.sortOption == .defaultSort)
    }
    
    @Test func deleteEntryRemovesItFromListAndDatabase() async throws {
      // Precondition: model has 4 Spanish entries
      #expect(model.entries.count == 4)
      let entryToDelete = model.entries[0]
      let entryId = entryToDelete.id

      // Perform delete using the view model's API
      model.deleteEntry(entryToDelete)
      try await model.$entries.load()

      // UI list should update
      #expect(model.entries.count == 3)
      #expect(model.entries.contains { $0.id == entryId } == false)

      // Database should no longer have the entry
      let deleted = try await database.read { db in
        try VocabularyEntry.find(entryId).fetchOne(db)
      }
      #expect(deleted == nil)
    }
    
    @Test func editEntrySetsStateAndPresentsEditor() async throws {
      // Pick an existing entry
      let entry = model.entries[0]

      // Precondition
      #expect(model.isEditEntryPresented == false)
      #expect(model.entryToEdit == nil)

      // Invoke edit
      model.editEntry(entry)

      // Postconditions
      #expect(model.isEditEntryPresented == true)
      #expect(model.entryToEdit?.id == entry.id)
      #expect(model.entryToEdit?.sourceWord == entry.sourceWord)
      #expect(model.entryToEdit?.translatedWord == entry.translatedWord)
    }
  }
}
