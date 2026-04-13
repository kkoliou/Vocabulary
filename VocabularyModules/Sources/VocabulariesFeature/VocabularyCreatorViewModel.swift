//
//  VocabularyCreatorViewModel.swift
//  VocabulariesFeature
//
//  Created by Konstantinos Kolioulis on 7/2/26.
//

import SwiftUI
import Foundation
import SQLiteData
import VocabularyDB
import Shared

@Observable @MainActor
class VocabularyCreatorViewModel {
  
  @ObservationIgnored @Dependency(\.defaultDatabase) var database
  @ObservationIgnored var alertTitle: LocalizedStringResource?
  var alertIsPresented = false
  var triggerSuccess = false
  var dismiss = false
  
  func addVocabularyTapped(vocabName: String) {
    let trimmed = vocabName.trimmed()
    guard !trimmed.isEmpty else {
      handleError(AddVocabularyError.emptyName)
      return
    }
    do {
      try database.write { db in
        let exists = try Vocabulary
          .where { $0.name.eq(trimmed) }
          .fetchCount(db) > 0
        
        if exists {
          throw AddVocabularyError.alreadyExists
        }
        
        try Vocabulary.insert {
          Vocabulary.Draft(name: trimmed, createdAt: Date())
        }
        .execute(db)
      }
      triggerSuccess = true
      dismiss = true
    } catch {
      handleError(error)
    }
  }
  
  private func handleError(_ error: Error) {
    guard let error = error as? AddVocabularyError else {
      displayAlert("Something went wrong")
      return
    }
    switch error {
    case .emptyName:
      displayAlert("Provide a vocabulary name")
    case .alreadyExists:
      displayAlert("The vocabulary already exists")
    }
  }
  
  private func displayAlert(_ message: StaticString) {
    alertTitle = Strings.localized(message)
    alertIsPresented = true
  }
}

enum AddVocabularyError: Error {
  case emptyName
  case alreadyExists
}
