//
//  VocabularyEntryAddViewModelTests.swift
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
          Vocabulary.Draft(id: UUID(-1), name: "Spanish", createdAt: Date())
          Vocabulary.Draft(id: UUID(-2), name: "French", createdAt: Date())
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
            isHighlighted: false
          )
        }
      }
    }
  )
  
  @MainActor
  struct VocabularyEntryAddViewModelTests {
    let model: VocabularyEntryAddViewModel
    let vocabulary: Vocabulary
    @Dependency(\.defaultDatabase) var database

    init() async throws {
      vocabulary = try await #require(
        _database.wrappedValue.read { db in
          try Vocabulary.find(UUID(-1)).fetchOne(db)
        }
      )
      model = VocabularyEntryAddViewModel(vocabulary: vocabulary)
    }

    @Test func initialState() async throws {
      #expect(model.source == "")
      #expect(model.translation == "")
      #expect(model.saveButtonDisabled == true)
      #expect(model.dismiss == false)
      #expect(model.triggerSuccess == false)
      #expect(model.alertTitle == nil)
      #expect(model.isAlertPresented == false)
      #expect(model.vocabulary.id == UUID(-1))
    }

    @Test func saveButtonEnabledWhenBothFieldsFilled() async throws {
      #expect(model.saveButtonDisabled == true)
      
      model.source = "thank you"
      #expect(model.saveButtonDisabled == true) // Still disabled, translation is empty
      
      model.translation = "gracias"
      #expect(model.saveButtonDisabled == false) // Now enabled
    }

    @Test func saveButtonDisabledWhenSourceIsEmpty() async throws {
      model.translation = "gracias"
      #expect(model.saveButtonDisabled == true)
      
      model.source = ""
      #expect(model.saveButtonDisabled == true)
    }

    @Test func saveButtonDisabledWhenTranslationIsEmpty() async throws {
      model.source = "thank you"
      #expect(model.saveButtonDisabled == true)
      
      model.translation = ""
      #expect(model.saveButtonDisabled == true)
    }

    @Test func saveButtonDisabledWhenOnlyWhitespace() async throws {
      model.source = "   "
      model.translation = "   "
      #expect(model.saveButtonDisabled == true)
    }

    @Test func saveEntryWithValidData() async throws {
      model.source = "thank you"
      model.translation = "gracias"
      
      model.saveButtonTapped()
      
      #expect(model.triggerSuccess == true)
      #expect(model.dismiss == true)
      #expect(model.isAlertPresented == false)
      
      // Verify entry was saved to database
      let entry = try await database.read { db in
        try VocabularyEntry
          .where { $0.sourceWord == "thank you" && $0.vocabularyID == UUID(-1) }
          .fetchOne(db)
      }
      
      let savedEntry = try #require(entry)
      #expect(savedEntry.sourceWord == "thank you")
      #expect(savedEntry.translatedWord == "gracias")
      #expect(savedEntry.vocabularyID == UUID(-1))
      #expect(savedEntry.isHighlighted == false)
    }

    @Test func saveEntryWithLeadingAndTrailingWhitespace() async throws {
      model.source = "  water  "
      model.translation = "  agua  "
      
      model.saveButtonTapped()
      
      #expect(model.triggerSuccess == true)
      
      // Verify whitespace was trimmed
      let entry = try await database.read { db in
        try VocabularyEntry
          .where { $0.sourceWord == "water" && $0.vocabularyID == UUID(-1) }
          .fetchOne(db)
      }
      
      let savedEntry = try #require(entry)
      #expect(savedEntry.sourceWord == "water")
      #expect(savedEntry.translatedWord == "agua")
    }

    @Test func saveEntryWithEmptySource() async throws {
      model.source = ""
      model.translation = "gracias"
      
      model.saveButtonTapped()
      
      #expect(model.triggerSuccess == false)
      #expect(model.dismiss == false)
      #expect(model.isAlertPresented == true)
      #expect(model.alertTitle == Strings.localized("Provide both original and translation"))
    }

    @Test func saveEntryWithEmptyTranslation() async throws {
      model.source = "thank you"
      model.translation = ""
      
      model.saveButtonTapped()
      
      #expect(model.triggerSuccess == false)
      #expect(model.dismiss == false)
      #expect(model.isAlertPresented == true)
      #expect(model.alertTitle == Strings.localized("Provide both original and translation"))
    }

    @Test func saveEntryWithWhitespaceOnlyFields() async throws {
      model.source = "   "
      model.translation = "   "
      
      model.saveButtonTapped()
      
      #expect(model.triggerSuccess == false)
      #expect(model.isAlertPresented == true)
      #expect(model.alertTitle == Strings.localized("Provide both original and translation"))
    }

    @Test func saveEntryThatAlreadyExists() async throws {
      model.source = "hello"
      model.translation = "hola nuevo"
      
      model.saveButtonTapped()
      
      #expect(model.triggerSuccess == false)
      #expect(model.dismiss == false)
      #expect(model.isAlertPresented == true)
      #expect(model.alertTitle == Strings.localized("An entry with this original word already exists in this vocabulary"))
      
      // Verify original entry is unchanged
      let entry = try await database.read { db in
        try VocabularyEntry
          .where { $0.sourceWord == "hello" && $0.vocabularyID == UUID(-1) }
          .fetchOne(db)
      }
      
      let existingEntry = try #require(entry)
      #expect(existingEntry.translatedWord == "hola") // Original translation
    }

    @Test func saveEntryWithExistingSourceButDifferentCase() async throws {
      // Test if "Hello" (capitalized) is treated differently from "hello"
      model.source = "Hello"
      model.translation = "Hola"
      
      model.saveButtonTapped()
      
      // Depending on business logic, this might succeed or fail
      // Adjust expectation based on your requirements
      #expect(model.triggerSuccess == true)
      
      let entry = try await database.read { db in
        try VocabularyEntry
          .where { $0.sourceWord == "Hello" && $0.vocabularyID == UUID(-1) }
          .fetchOne(db)
      }
      
      #expect(entry != nil)
    }

    @Test func saveEntryWithSpecialCharacters() async throws {
      model.source = "café"
      model.translation = "coffee"
      
      model.saveButtonTapped()
      
      #expect(model.triggerSuccess == true)
      
      let entry = try await database.read { db in
        try VocabularyEntry
          .where { $0.sourceWord == "café" && $0.vocabularyID == UUID(-1) }
          .fetchOne(db)
      }
      
      #expect(entry != nil)
    }

    @Test func saveEntrySetsIsHighlightedToFalse() async throws {
      model.source = "book"
      model.translation = "libro"
      
      model.saveButtonTapped()
      
      let entry = try await database.read { db in
        try VocabularyEntry
          .where { $0.sourceWord == "book" && $0.vocabularyID == UUID(-1) }
          .fetchOne(db)
      }
      
      let savedEntry = try #require(entry)
      #expect(savedEntry.isHighlighted == false)
    }

    @Test func saveEntryInDifferentVocabulary() async throws {
      // Create model for French vocabulary
      let frenchVocab = try await #require(
        database.read { db in
          try Vocabulary.find(UUID(-2)).fetchOne(db)
        }
      )
      let frenchModel = VocabularyEntryAddViewModel(vocabulary: frenchVocab)
      
      // Same source word but in different vocabulary should succeed
      frenchModel.source = "hello"
      frenchModel.translation = "bonjour"
      
      frenchModel.saveButtonTapped()
      
      #expect(frenchModel.triggerSuccess == true)
      
      // Verify both entries exist in their respective vocabularies
      let spanishEntry = try await database.read { db in
        try VocabularyEntry
          .where { $0.sourceWord == "hello" && $0.vocabularyID == UUID(-1) }
          .fetchOne(db)
      }
      
      let frenchEntry = try await database.read { db in
        try VocabularyEntry
          .where { $0.sourceWord == "hello" && $0.vocabularyID == UUID(-2) }
          .fetchOne(db)
      }
      
      #expect(spanishEntry != nil)
      #expect(frenchEntry != nil)
      #expect(spanishEntry?.translatedWord == "hola")
      #expect(frenchEntry?.translatedWord == "bonjour")
    }

    @Test func saveButtonStateUpdatesWhenClearingFields() async throws {
      model.source = "hello"
      model.translation = "hola"
      #expect(model.saveButtonDisabled == false)
      
      model.source = ""
      #expect(model.saveButtonDisabled == true)
      
      model.source = "hello"
      #expect(model.saveButtonDisabled == false)
      
      model.translation = ""
      #expect(model.saveButtonDisabled == true)
    }

    @Test func saveMultipleEntriesSequentially() async throws {
      // First entry
      model.source = "water"
      model.translation = "agua"
      model.saveButtonTapped()
      #expect(model.triggerSuccess == true)
      
      // Second entry with new model
      let model2 = VocabularyEntryAddViewModel(vocabulary: vocabulary)
      model2.source = "fire"
      model2.translation = "fuego"
      model2.saveButtonTapped()
      #expect(model2.triggerSuccess == true)
      
      // Verify both entries exist
      let count = try await database.read { db in
        try VocabularyEntry
          .where { $0.vocabularyID == UUID(-1) }
          .fetchCount(db)
      }
      
      #expect(count == 4) // 2 seeded + 2 new
    }

    @Test func saveEntryWithLongText() async throws {
      let longSource = String(repeating: "a", count: 200)
      let longTranslation = String(repeating: "b", count: 200)
      
      model.source = longSource
      model.translation = longTranslation
      
      model.saveButtonTapped()
      
      #expect(model.triggerSuccess == true)
      
      let entry = try await database.read { db in
        try VocabularyEntry
          .where { $0.sourceWord == longSource && $0.vocabularyID == UUID(-1) }
          .fetchOne(db)
      }
      
      let savedEntry = try #require(entry)
      #expect(savedEntry.sourceWord == longSource)
      #expect(savedEntry.translatedWord == longTranslation)
    }

    @Test func saveEntryWithMultipleWords() async throws {
      model.source = "good morning"
      model.translation = "buenos días"
      
      model.saveButtonTapped()
      
      #expect(model.triggerSuccess == true)
      
      let entry = try await database.read { db in
        try VocabularyEntry
          .where { $0.sourceWord == "good morning" && $0.vocabularyID == UUID(-1) }
          .fetchOne(db)
      }
      
      #expect(entry != nil)
    }

    @Test func saveButtonStateWithWhitespaceInMiddle() async throws {
      model.source = "good morning"
      model.translation = "buenos días"
      
      #expect(model.saveButtonDisabled == false)
    }

    @Test func alertDismissalState() async throws {
      model.source = ""
      model.translation = ""
      model.saveButtonTapped()
      
      #expect(model.isAlertPresented == true)
      #expect(model.dismiss == false)
      #expect(model.triggerSuccess == false)
    }
  }
}
