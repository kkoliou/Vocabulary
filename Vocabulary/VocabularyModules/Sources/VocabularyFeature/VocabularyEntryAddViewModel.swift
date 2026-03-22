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
  let validator: ImportValidatorProtocol
  
  init(
    vocabulary: Vocabulary,
    entryToEdit: VocabularyEntry? = nil,
    validator: ImportValidatorProtocol = ImportValidator()
  ) {
    self.vocabulary = vocabulary
    self.entryToEdit = entryToEdit
    self.validator = validator
    
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
      if entryToEdit != nil {
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
    try await validator.validateImportLimits(
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
  
  func handleError(_ error: Error) {
    if let error = error as? ImportEntriesError {
      switch error {
      case .vocabularyLimitExceeded(let limitChecks):
        displayAlert(
          LocalizedStringResource(
            "This vocabulary has reached its limit of \(limitChecks.limit) entries.",
            bundle: .sharedModule
          )
        )
      case .appLimitExceeded(let limitChecks):
        displayAlert(
          LocalizedStringResource(
            "The app has reached its limit of \(limitChecks.limit) total entries across all vocabularies.",
            bundle: .sharedModule
          )
        )
      }
    } else if let error = error as? AddVocabularyEntryError {
      switch error {
      case .emptyName:
        displayAlert(Strings.localized("Provide both original and translation."))
      case .alreadyExists:
        displayAlert(Strings.localized("An entry with this original word already exists in this vocabulary."))
      }
    } else {
      displayAlert(Strings.localized("Something went wrong."))
    }
  }
  
  private func displayAlert(_ message: LocalizedStringResource) {
    alertTitle = message
    isAlertPresented = true
  }
}

enum AddVocabularyEntryError: Error {
  case emptyName
  case alreadyExists
}
