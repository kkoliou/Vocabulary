//
//  VocabulariesViewModel.swift
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
public class VocabulariesViewModel {
  
  @ObservationIgnored @Dependency(\.defaultDatabase) var database
  @ObservationIgnored @FetchAll(Vocabulary.none) var vocabularies
  var addVocabIsPresented = false
  
  public init() {}
  
  func doInit() async {
    _ = await withErrorReporting {
      try await $vocabularies
        .load(
          Vocabulary
            .order(by: \.createdAt)
        )
    }
  }
  
  func addVocabularyTapped() {
    addVocabIsPresented = true
  }
  
  func deleteVocabularies(at offsets: IndexSet) async {
    withErrorReporting {
      try database.write { db in
        try Vocabulary.find(offsets.map { vocabularies[$0].id })
          .delete()
          .execute(db)
      }
    }
  }
  
}
