//
//  VocabularyEntryAddViewModel.swift
//  VocabularyFeature
//
//  Created by Konstantinos Kolioulis on 8/2/26.
//

import SQLiteData
import VocabularyDB
import Observation
import Shared
import Foundation

@Observable @MainActor
class VocabularyEntryAddViewModel {
  
  @ObservationIgnored @Dependency(\.defaultDatabase) var database
  let vocabulary: Vocabulary
  let entryToEdit: VocabularyEntry?
  var source: String = "" {
    didSet {
      checkSaveButtonState()
    }
  }
  var translation: String = "" {
    didSet {
      checkSaveButtonState()
    }
  }
  var saveButtonDisabled: Bool = true
  var dismiss = false
  var triggerSuccess = false
  var alertTitle: LocalizedStringResource?
  var isAlertPresented = false
  
  init(vocabulary: Vocabulary, entryToEdit: VocabularyEntry? = nil) {
    self.vocabulary = vocabulary
    self.entryToEdit = entryToEdit
    
    if let entry = entryToEdit {
      self.source = entry.sourceWord
      self.translation = entry.translatedWord
    }
  }
  
  private func checkSaveButtonState() {
    let sourceIsEmpty = source.trimmed().isEmpty
    let translationIsEmpty = translation.trimmed().isEmpty
    saveButtonDisabled = sourceIsEmpty || translationIsEmpty
  }
  
  func saveButtonTapped() async {
    let sourceTrimmed = source.trimmed()
    let translationTrimmed = translation.trimmed()
    
    if sourceTrimmed.isEmpty || translationTrimmed.isEmpty {
      handleError(AddVocabularyEntryError.emptyName)
      return
    }
    
    do {
      if let entryToEdit = entryToEdit {
        try await updateExistingEntry(sourceTrimmed, translationTrimmed)
      } else {
        try await createNewEntry(sourceTrimmed, translationTrimmed)
      }
      triggerSuccess = true
      dismiss = true
    } catch {
      handleError(error)
    }
  }
  
  private func updateExistingEntry(_ source: String, _ translation: String) async throws {
    try await database.write { db in
      try VocabularyEntry
        .find(entryToEdit!.id)
        .update {
          $0.sourceWord = source
          $0.translatedWord = translation
        }
        .execute(db)
    }
  }
  
  private func createNewEntry(_ source: String, _ translation: String) async throws {
    try await ImportValidator().validateImportLimits(
      entriesCount: 1,
      vocabularyId: vocabulary.id,
      database: database
    )
    
    try await database.write { db in
      let exists = try VocabularyEntry
        .where { $0.sourceWord == source && $0.vocabularyID == vocabulary.id }
        .fetchCount(db) > 0
      
      if exists {
        throw AddVocabularyEntryError.alreadyExists
      }
      
      try VocabularyEntry.insert {
        VocabularyEntry.Draft(
          vocabularyID: vocabulary.id,
          sourceWord: source,
          translatedWord: translation,
          isHighlighted: false
        )
      }
      .execute(db)
    }
  }
  
  private func validateEntryLimits(_ db: Database) throws {
    let vocabularyEntryCount = try VocabularyEntry
      .where { $0.vocabularyID == vocabulary.id }
      .fetchCount(db)
    
    let totalEntryCount = try VocabularyEntry.fetchCount(db)
    
    if vocabularyEntryCount >= 5000 {
      throw AddVocabularyEntryError.vocabularyLimitExceeded(5000)
    }
    
    if totalEntryCount >= 50000 {
      throw AddVocabularyEntryError.appLimitExceeded(50000)
    }
  }
  
  func handleError(_ error: Error) {
    guard let error = error as? AddVocabularyEntryError else {
      displayAlert("Something went wrong")
      return
    }
    switch error {
    case .emptyName:
      displayAlert("Provide both original and translation")
    case .alreadyExists:
      displayAlert("An entry with this original word already exists in this vocabulary")
    case .vocabularyLimitExceeded(let limit):
      displayAlert("This vocabulary has reached its limit of \(limit) entries")
    case .appLimitExceeded(let limit):
      displayAlert("The app has reached its limit of \(limit) total entries across all vocabularies")
    }
  }
  
  private func displayAlert(_ message: StaticString) {
    alertTitle = Strings.localized(message)
    isAlertPresented = true
  }
}

enum AddVocabularyEntryError: Error {
  case emptyName
  case alreadyExists
  case vocabularyLimitExceeded(Int)
  case appLimitExceeded(Int)
}
