//
//  VocabularyEntriesAddViewModelTests.swift
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
        }
      }
    }
  )
  
  @MainActor
  struct VocabularyEntriesAddViewModelTests {
    let model: VocabularyEntriesAddViewModel
    let vocabulary: Vocabulary
    @Dependency(\.defaultDatabase) var database

    init() async throws {
      vocabulary = try await #require(
        _database.wrappedValue.read { db in
          try Vocabulary.find(UUID(-1)).fetchOne(db)
        }
      )
      model = VocabularyEntriesAddViewModel(vocabulary: vocabulary)
    }

    @Test func initialState() async throws {
      #expect(model.isPickerPresented == false)
      #expect(model.isImporting == false)
      #expect(model.fileName == nil)
      #expect(model.fileContent == nil)
      #expect(model.errorMessage == nil)
      #expect(model.dismiss == false)
      #expect(model.triggerSuccess == false)
      #expect(model.hasSelectedFile == false)
      #expect(model.vocabulary.id == UUID(-1))
    }

    @Test func selectFilePresentsFilePicker() async throws {
      model.selectFile()
      
      #expect(model.isPickerPresented == true)
    }

    @Test func hasSelectedFileReturnsTrueWhenFileContentExists() async throws {
      #expect(model.hasSelectedFile == false)
      
      model.fileContent = "source,translation\nhello,hola"
      
      #expect(model.hasSelectedFile == true)
    }

    @Test func clearFileResetsState() async throws {
      model.fileContent = "source,translation\nhello,hola"
      model.fileName = "test.csv"
      model.errorMessage = "Some error"
      
      model.clearFile()
      
      #expect(model.fileContent == nil)
      #expect(model.fileName == nil)
      #expect(model.errorMessage == nil)
    }

    @Test func importEntriesWithValidCsvContent() async throws {
      let csvContent = """
      source,translation
      hello,hola
      goodbye,adiós
      thank you,gracias
      """
      
      model.fileContent = csvContent
      
      await model.importEntries()
      
      #expect(model.triggerSuccess == true)
      #expect(model.dismiss == true)
      #expect(model.isImporting == false)
      #expect(model.errorMessage == nil)
      
      // Verify entries were stored in database
      let entries = try await database.read { db in
        try VocabularyEntry
          .where { $0.vocabularyID == UUID(-1) }
          .fetchAll(db)
      }
      
      #expect(entries.count == 4) // 1 existing + 3 new
      
      let newEntries = entries.filter { $0.id != UUID(-10) }
      #expect(newEntries.count == 3)
      
      let sourceWords = newEntries.map(\.sourceWord).sorted()
      #expect(sourceWords == ["goodbye", "hello", "thank you"])
      
      let translatedWords = newEntries.map(\.translatedWord).sorted()
      #expect(translatedWords == ["adiós", "gracias", "hola"])
    }

    @Test func importEntriesWithEmptyFileContent() async throws {
      model.fileContent = nil
      
      await model.importEntries()
      
      // Should return early without doing anything
      #expect(model.triggerSuccess == false)
      #expect(model.dismiss == false)
      #expect(model.errorMessage == nil)
    }

    @Test func importEntriesWithInvalidCsvFormat() async throws {
      let invalidCsv = """
      not a valid csv format
      missing proper structure
      """
      
      model.fileContent = invalidCsv
      
      await model.importEntries()
      
      #expect(model.triggerSuccess == false)
      #expect(model.dismiss == false)
      #expect(model.isImporting == false)
    }

    @Test func importEntriesWithMissingRequiredFields() async throws {
      let csvWithMissingFields = """
      source,translation
      hello,hola
      goodbye,
      ,gracias
      """
      
      model.fileContent = csvWithMissingFields
      
      await model.importEntries()
      
      #expect(model.triggerSuccess == true)
      #expect(model.dismiss == true)
      #expect(model.isImporting == false)
      
      let entries = try await database.read { db in
        try VocabularyEntry
          .where { $0.vocabularyID == UUID(-1) }
          .fetchAll(db)
      }
      #expect(entries.count == 2) // Entries with empty fiels are skipped
    }

    @Test func importEntriesWithSingleEntry() async throws {
      let csvContent = """
      source,translation
      hello,hola
      """
      
      model.fileContent = csvContent
      
      await model.importEntries()
      
      #expect(model.triggerSuccess == true)
      #expect(model.dismiss == true)
      
      let entries = try await database.read { db in
        try VocabularyEntry
          .where { $0.vocabularyID == UUID(-1) }
          .fetchAll(db)
      }
      
      #expect(entries.count == 2) // 1 existing + 1 new
    }

    @Test func importEntriesWithSpecialCharacters() async throws {
      let csvContent = """
      source,translation
      café,café
      niño,child
      señor,mister
      """
      
      model.fileContent = csvContent
      
      await model.importEntries()
      
      #expect(model.triggerSuccess == true)
      
      let entries = try await database.read { db in
        try VocabularyEntry
          .where { $0.vocabularyID == UUID(-1) }
          .order(by: \.sourceWord)
          .fetchAll(db)
      }
      
      let newEntries = entries.filter { $0.id != UUID(-10) }
      #expect(newEntries.map(\.sourceWord).contains("café"))
      #expect(newEntries.map(\.sourceWord).contains("niño"))
      #expect(newEntries.map(\.sourceWord).contains("señor"))
    }

    @Test func importEntriesWithWhitespaceInValues() async throws {
      let csvContent = """
      source,translation
      hello world,hola mundo
      good morning,buenos días
      """
      
      model.fileContent = csvContent
      
      await model.importEntries()
      
      #expect(model.triggerSuccess == true)
      
      let entries = try await database.read { db in
        try VocabularyEntry
          .where { $0.vocabularyID == UUID(-1) }
          .fetchAll(db)
      }
      
      let newEntries = entries.filter { $0.id != UUID(-10) }
      #expect(newEntries.count == 2)
      #expect(newEntries.map(\.sourceWord).contains("hello world"))
      #expect(newEntries.map(\.translatedWord).contains("hola mundo"))
    }

    @Test func importEntriesIsHighlightedDefaultsToFalse() async throws {
      let csvContent = """
      source,translation
      hello,hola
      """
      
      model.fileContent = csvContent
      
      await model.importEntries()
      
      let entries = try await database.read { db in
        try VocabularyEntry
          .where { $0.vocabularyID == UUID(-1) }
          .fetchAll(db)
      }
      
      // All entries should have isHighlighted = false
      #expect(entries.allSatisfy { $0.isHighlighted == false })
    }

    @Test func importEntriesAssignsCorrectVocabularyID() async throws {
      let csvContent = """
      source,translation
      bonjour,hello
      merci,thank you
      """
      
      // Create model for French vocabulary
      let frenchVocab = try await #require(
        database.read { db in
          try Vocabulary.find(UUID(-2)).fetchOne(db)
        }
      )
      let frenchModel = VocabularyEntriesAddViewModel(vocabulary: frenchVocab)
      frenchModel.fileContent = csvContent
      
      await frenchModel.importEntries()
      
      let entries = try await database.read { db in
        try VocabularyEntry
          .where { $0.vocabularyID == UUID(-2) }
          .fetchAll(db)
      }
      
      #expect(entries.count == 2)
      #expect(entries.allSatisfy { $0.vocabularyID == UUID(-2) })
    }

    @Test func importEntriesWithLargeDataset() async throws {
      var csvLines = ["source,translation"]
      for i in 1...100 {
        csvLines.append("word\(i),traducción\(i)")
      }
      let csvContent = csvLines.joined(separator: "\n")
      
      model.fileContent = csvContent
      
      await model.importEntries()
      
      #expect(model.triggerSuccess == true)
      
      let entries = try await database.read { db in
        try VocabularyEntry
          .where { $0.vocabularyID == UUID(-1) }
          .fetchAll(db)
      }
      
      #expect(entries.count == 101) // 1 existing + 100 new
    }

    @Test func importingStateManagement() async throws {
      let csvContent = """
      source,translation
      hello,hola
      """
      
      model.fileContent = csvContent
      
      #expect(model.isImporting == false)
      
      // Note: In a real async test, you'd need to check during execution
      // For now, we verify the final state
      await model.importEntries()
      
      #expect(model.isImporting == false)
    }

    @Test func multipleImportsToSameVocabulary() async throws {
      let firstBatch = """
      source,translation
      hello,hola
      """
      
      model.fileContent = firstBatch
      await model.importEntries()
      
      let secondBatch = """
      source,translation
      goodbye,adiós
      """
      
      let model2 = VocabularyEntriesAddViewModel(vocabulary: vocabulary)
      model2.fileContent = secondBatch
      await model2.importEntries()
      
      let entries = try await database.read { db in
        try VocabularyEntry
          .where { $0.vocabularyID == UUID(-1) }
          .fetchAll(db)
      }
      
      #expect(entries.count == 3) // 1 existing + 2 new from both imports
    }

    @Test func handleFileSelectionSuccess() async throws {
      // Create a temporary file
      let tempDir = FileManager.default.temporaryDirectory
      let fileURL = tempDir.appendingPathComponent("test.csv")
      let csvContent = "source,translation\nhello,hola"
      try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
      
      defer {
        try? FileManager.default.removeItem(at: fileURL)
      }
      
      model.handleFileSelection(.success([fileURL]))
      
      #expect(model.fileName == "test.csv")
      #expect(model.fileContent != nil)
      #expect(model.hasSelectedFile == true)
    }

    @Test func handleFileSelectionWithEmptyURLArray() async throws {
      model.handleFileSelection(.success([]))
      
      #expect(model.fileName == nil)
      #expect(model.fileContent == nil)
    }

    @Test func importEntriesThrowsVocabularyLimitExceeded() async throws {
      let mockValidator = MockImportValidator()
      mockValidator.shouldThrowVocabularyLimit = true
      
      let modelWithMock = VocabularyEntriesAddViewModel(
        vocabulary: vocabulary,
        validator: mockValidator
      )
      
      modelWithMock.fileContent = """
        source,translation
        hello,hola
        goodbye,adiós
        """
      
      await modelWithMock.importEntries()
      
      #expect(modelWithMock.triggerSuccess == false)
      #expect(modelWithMock.dismiss == false)
      #expect(modelWithMock.isImporting == false)
      #expect(modelWithMock.errorMessage != nil)
    }

    @Test func importEntriesThrowsAppLimitExceeded() async throws {
      let mockValidator = MockImportValidator()
      mockValidator.shouldThrowAppLimit = true
      
      let modelWithMock = VocabularyEntriesAddViewModel(
        vocabulary: vocabulary,
        validator: mockValidator
      )
      
      modelWithMock.fileContent = """
        source,translation
        hello,hola
        goodbye,adiós
        """
      
      await modelWithMock.importEntries()
      
      #expect(modelWithMock.triggerSuccess == false)
      #expect(modelWithMock.dismiss == false)
      #expect(modelWithMock.isImporting == false)
      #expect(modelWithMock.errorMessage != nil)
    }

    @Test func importEntriesErrorMessageForVocabularyLimitExceeded() async throws {
      let mockValidator = MockImportValidator()
      mockValidator.availableSlots = 10
      mockValidator.shouldThrowVocabularyLimit = true
      
      let modelWithMock = VocabularyEntriesAddViewModel(
        vocabulary: vocabulary,
        validator: mockValidator
      )
      
      modelWithMock.fileContent = """
        source,translation
        hello,hola
        """
      
      await modelWithMock.importEntries()
      
      #expect(modelWithMock.errorMessage != nil)
    }

    @Test func importEntriesErrorMessageForAppLimitExceeded() async throws {
      let mockValidator = MockImportValidator()
      mockValidator.availableSlots = 5
      mockValidator.shouldThrowAppLimit = true
      
      let modelWithMock = VocabularyEntriesAddViewModel(
        vocabulary: vocabulary,
        validator: mockValidator
      )
      
      modelWithMock.fileContent = """
        source,translation
        hello,hola
        """
      
      await modelWithMock.importEntries()
      
      #expect(modelWithMock.errorMessage != nil)
    }
  }
}

@MainActor
final class MockImportValidator: ImportValidatorProtocol {
  var shouldThrowVocabularyLimit = false
  var shouldThrowAppLimit = false
  var availableSlots = 100
  
  func validateImportLimits(
    entriesCount: Int,
    vocabularyId: UUID,
    database: DatabaseReader
  ) async throws {
    if shouldThrowVocabularyLimit {
      throw ImportEntriesError.vocabularyLimitExceeded(
        .init(limit: 5000, availableSlots: availableSlots)
      )
    }
    
    if shouldThrowAppLimit {
      throw ImportEntriesError.appLimitExceeded(
        .init(limit: 50000, availableSlots: availableSlots)
      )
    }
  }
}

@Suite(
  .dependencies {
    $0.uuid = .incrementing
    try $0.bootstrapDatabase()
  }
)
struct BaseSuite {}
