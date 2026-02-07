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
  
  func addVocabularyTapped(vocabName: String) throws {
    let trimmed = vocabName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { throw AddVocabularyError.emptyName }
    try database.write { db in
      let exists = try Vocabulary
        .where { $0.name == trimmed }
        .fetchCount(db) > 0
      
      if exists {
        throw AddVocabularyError.alreadyExists
      }
      
      try Vocabulary.insert {
        Vocabulary.Draft(name: trimmed, createdAt: Date())
      }
      .execute(db)
    }
  }
  
  func handleError(_ error: Error) {
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
