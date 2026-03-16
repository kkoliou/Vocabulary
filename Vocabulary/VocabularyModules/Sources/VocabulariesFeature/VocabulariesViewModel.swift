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
  @ObservationIgnored var firstInitExecuted = false
  var addVocabIsPresented = false
  var isLoading = false
  var isAddSampleVocabsLoading = false
  
  public init() {}
  
  func doInit() async {
    setLoadingIfNeeded(true)
    _ = await withErrorReporting {
      try await $vocabularies
        .load(
          Vocabulary
            .order(by: \.createdAt),
          animation: .default
        )
    }
    setLoadingIfNeeded(false)
    firstInitExecuted = true
  }
  
  private func setLoadingIfNeeded(_ loading: Bool) {
    if firstInitExecuted { return }
    isLoading = loading
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
  
  func addPreMadeVocabularies() async {
    isAddSampleVocabsLoading = true
    
    try? await Task.sleep(for: .seconds(2))
    
    isAddSampleVocabsLoading = false
  }
}
