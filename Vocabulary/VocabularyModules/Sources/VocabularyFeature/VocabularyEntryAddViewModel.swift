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
  
  init(vocabulary: Vocabulary) {
    self.vocabulary = vocabulary
  }
  
  private func checkSaveButtonState() {
    let sourceIsEmpty = source.trimmed().isEmpty
    let translationIsEmpty = translation.trimmed().isEmpty
    saveButtonDisabled = sourceIsEmpty || translationIsEmpty
  }
  
  func saveButtonTapped() {
    let sourceTrimmed = source.trimmed()
    let translationTrimmed = translation.trimmed()
    if sourceTrimmed.isEmpty || translationTrimmed.isEmpty {
      handleError(AddVocabularyEntryError.emptyName)
      return
    }
    do {
      try database.write { db in
        let exists = try VocabularyEntry
          .where { $0.sourceWord == sourceTrimmed && $0.vocabularyID == vocabulary.id }
          .fetchCount(db) > 0

        if exists {
          throw AddVocabularyEntryError.alreadyExists
        }

        try VocabularyEntry.insert {
          VocabularyEntry.Draft(
            vocabularyID: vocabulary.id,
            sourceWord: sourceTrimmed,
            translatedWord: translationTrimmed,
            isHighlighted: false
          )
        }
        .execute(db)
      }
      triggerSuccess = true
      dismiss = true
    } catch {
      handleError(error)
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
}
