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
      
      await model.saveButtonTapped()
      
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
      
      await model.saveButtonTapped()
      
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
      
      await model.saveButtonTapped()
      
      #expect(model.triggerSuccess == false)
      #expect(model.dismiss == false)
      #expect(model.isAlertPresented == true)
      #expect(model.alertTitle == Strings.localized("Provide both original and translation."))
    }

    @Test func saveEntryWithEmptyTranslation() async throws {
      model.source = "thank you"
      model.translation = ""
      
      await model.saveButtonTapped()
      
      #expect(model.triggerSuccess == false)
      #expect(model.dismiss == false)
      #expect(model.isAlertPresented == true)
      #expect(model.alertTitle == Strings.localized("Provide both original and translation."))
    }

    @Test func saveEntryWithWhitespaceOnlyFields() async throws {
      model.source = "   "
      model.translation = "   "
      
      await model.saveButtonTapped()
      
      #expect(model.triggerSuccess == false)
      #expect(model.isAlertPresented == true)
      #expect(model.alertTitle == Strings.localized("Provide both original and translation."))
    }

    @Test func saveEntryThatAlreadyExists() async throws {
      model.source = "hello"
      model.translation = "hola nuevo"
      
      await model.saveButtonTapped()
      
      #expect(model.triggerSuccess == false)
      #expect(model.dismiss == false)
      #expect(model.isAlertPresented == true)
      #expect(model.alertTitle == Strings.localized("An entry with this original word already exists in this vocabulary."))
      
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
      
      await model.saveButtonTapped()
      
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
      
      await model.saveButtonTapped()
      
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
      
      await model.saveButtonTapped()
      
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
      
      await frenchModel.saveButtonTapped()
      
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
      await model.saveButtonTapped()
      #expect(model.triggerSuccess == true)
      
      // Second entry with new model
      let model2 = VocabularyEntryAddViewModel(vocabulary: vocabulary)
      model2.source = "fire"
      model2.translation = "fuego"
      await model2.saveButtonTapped()
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
      
      await model.saveButtonTapped()
      
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
      
      await model.saveButtonTapped()
      
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
      await model.saveButtonTapped()
      
      #expect(model.isAlertPresented == true)
      #expect(model.dismiss == false)
      #expect(model.triggerSuccess == false)
    }

    @Test func editExistingEntrySuccessfully() async throws {
      // Fetch an existing entry ("hello" -> "hola") and edit its translation
      let original = try await database.read { db in
        try VocabularyEntry
          .where { $0.sourceWord == "hello" && $0.vocabularyID == UUID(-1) }
          .fetchOne(db)
      }
      let existing = try #require(original)

      // Assuming the ViewModel can be initialized for editing with an existing entry
      let editModel = VocabularyEntryAddViewModel(vocabulary: vocabulary, entryToEdit: existing)

      // Pre-filled fields should reflect existing values
      #expect(editModel.source == "hello")
      #expect(editModel.translation == "hola")
      #expect(editModel.saveButtonDisabled == false)

      // Change only the translation
      editModel.translation = "hola!!!"
      await editModel.saveButtonTapped()

      #expect(editModel.triggerSuccess == true)
      #expect(editModel.dismiss == true)

      // Verify database reflects the updated translation
      let updated = try await database.read { db in
        try VocabularyEntry
          .where { $0.sourceWord == "hello" && $0.vocabularyID == UUID(-1) }
          .fetchOne(db)
      }
      let updatedEntry = try #require(updated)
      #expect(updatedEntry.translatedWord == "hola!!!")
      #expect(updatedEntry.sourceWord == "hello")
    }

    @Test func editExistingEntryTrimWhitespace() async throws {
      let original = try await database.read { db in
        try VocabularyEntry
          .where { $0.sourceWord == "goodbye" && $0.vocabularyID == UUID(-1) }
          .fetchOne(db)
      }
      let existing = try #require(original)

      let editModel = VocabularyEntryAddViewModel(vocabulary: vocabulary, entryToEdit: existing)

      editModel.source = "  goodbye  "
      editModel.translation = "  adiós!!!  "
      await editModel.saveButtonTapped()

      #expect(editModel.triggerSuccess == true)

      let updated = try await database.read { db in
        try VocabularyEntry
          .where { $0.sourceWord == "goodbye" && $0.vocabularyID == UUID(-1) }
          .fetchOne(db)
      }
      let updatedEntry = try #require(updated)
      #expect(updatedEntry.sourceWord == "goodbye")
      #expect(updatedEntry.translatedWord == "adiós!!!")
    }

    @Test func editExistingEntryEmptyFieldsShowsAlert() async throws {
      let original = try await database.read { db in
        try VocabularyEntry
          .where { $0.sourceWord == "hello" && $0.vocabularyID == UUID(-1) }
          .fetchOne(db)
      }
      let existing = try #require(original)

      let editModel = VocabularyEntryAddViewModel(vocabulary: vocabulary, entryToEdit: existing)

      editModel.source = ""
      editModel.translation = ""
      await editModel.saveButtonTapped()

      #expect(editModel.triggerSuccess == false)
      #expect(editModel.isAlertPresented == true)
      #expect(editModel.alertTitle == Strings.localized("Provide both original and translation."))
    }

    @Test func editExistingEntryWhitespaceOnlyShowsAlert() async throws {
      let original = try await database.read { db in
        try VocabularyEntry
          .where { $0.sourceWord == "hello" && $0.vocabularyID == UUID(-1) }
          .fetchOne(db)
      }
      let existing = try #require(original)

      let editModel = VocabularyEntryAddViewModel(vocabulary: vocabulary, entryToEdit: existing)

      editModel.source = "   "
      editModel.translation = "   "
      await editModel.saveButtonTapped()

      #expect(editModel.triggerSuccess == false)
      #expect(editModel.isAlertPresented == true)
      #expect(editModel.alertTitle == Strings.localized("Provide both original and translation."))
    }

    @Test func editExistingEntryNoChangesStillValid() async throws {
      let original = try await database.read { db in
        try VocabularyEntry
          .where { $0.sourceWord == "hello" && $0.vocabularyID == UUID(-1) }
          .fetchOne(db)
      }
      let existing = try #require(original)

      let editModel = VocabularyEntryAddViewModel(vocabulary: vocabulary, entryToEdit: existing)

      // No changes
      await editModel.saveButtonTapped()

      #expect(editModel.triggerSuccess == true)
      #expect(editModel.dismiss == true)

      // Verify nothing changed
      let after = try await database.read { db in
        try VocabularyEntry
          .where { $0.id == existing.id }
          .fetchOne(db)
      }
      let afterEntry = try #require(after)
      #expect(afterEntry.sourceWord == existing.sourceWord)
      #expect(afterEntry.translatedWord == existing.translatedWord)
    }

    @Test func createEntryThrowsVocabularyLimitExceeded() async throws {
      let mockValidator = MockEntryImportValidator()
      mockValidator.shouldThrowVocabularyLimit = true
      
      let modelWithMock = VocabularyEntryAddViewModel(
        vocabulary: vocabulary,
        validator: mockValidator
      )
      
      modelWithMock.source = "new word"
      modelWithMock.translation = "new translation"
      
      await modelWithMock.saveButtonTapped()
      
      #expect(modelWithMock.triggerSuccess == false)
      #expect(modelWithMock.dismiss == false)
      #expect(modelWithMock.isAlertPresented == true)
      #expect(modelWithMock.alertTitle != nil)
    }

    @Test func createEntryThrowsAppLimitExceeded() async throws {
      let mockValidator = MockEntryImportValidator()
      mockValidator.shouldThrowAppLimit = true
      
      let modelWithMock = VocabularyEntryAddViewModel(
        vocabulary: vocabulary,
        validator: mockValidator
      )
      
      modelWithMock.source = "new word"
      modelWithMock.translation = "new translation"
      
      await modelWithMock.saveButtonTapped()
      
      #expect(modelWithMock.triggerSuccess == false)
      #expect(modelWithMock.dismiss == false)
      #expect(modelWithMock.isAlertPresented == true)
      #expect(modelWithMock.alertTitle != nil)
    }

    @Test func editingExistingEntrySkipsValidation() async throws {
      let original = try await database.read { db in
        try VocabularyEntry
          .where { $0.sourceWord == "hello" && $0.vocabularyID == UUID(-1) }
          .fetchOne(db)
      }
      let existing = try #require(original)

      let mockValidator = MockEntryImportValidator()
      mockValidator.shouldThrowVocabularyLimit = true
      
      let editModel = VocabularyEntryAddViewModel(
        vocabulary: vocabulary,
        entryToEdit: existing,
        validator: mockValidator
      )

      editModel.translation = "updated translation"
      await editModel.saveButtonTapped()

      #expect(editModel.triggerSuccess == true)
      #expect(editModel.dismiss == true)

      let updated = try await database.read { db in
        try VocabularyEntry
          .where { $0.id == existing.id }
          .fetchOne(db)
      }
      let updatedEntry = try #require(updated)
      #expect(updatedEntry.translatedWord == "updated translation")
    }
  }
}

@MainActor
final class MockEntryImportValidator: ImportValidatorProtocol {
  var shouldThrowVocabularyLimit = false
  var shouldThrowAppLimit = false
  
  func validateImportLimits(
    entriesCount: Int,
    vocabularyId: UUID,
    database: DatabaseReader
  ) async throws {
    if shouldThrowVocabularyLimit {
      throw ImportEntriesError.vocabularyLimitExceeded(
        .init(limit: 5000, availableSlots: 10)
      )
    }
    
    if shouldThrowAppLimit {
      throw ImportEntriesError.appLimitExceeded(
        .init(limit: 50000, availableSlots: 20)
      )
    }
  }
}
