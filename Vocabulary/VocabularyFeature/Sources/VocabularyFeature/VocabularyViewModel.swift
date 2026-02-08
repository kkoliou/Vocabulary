//
//  VocabularyViewModel.swift
//  VocabularyFeature
//
//  Created by Konstantinos Kolioulis on 8/2/26.
//

import SQLiteData
import VocabularyDB
import Observation

@Observable @MainActor
public class VocabularyViewModel {
  
  @ObservationIgnored @Dependency(\.defaultDatabase) var database
  @ObservationIgnored @FetchAll(VocabularyEntry.none) var words
  var isAddEntryPresented = false
  let vocabulary: Vocabulary
  
  public init(vocabulary: Vocabulary) {
    self.vocabulary = vocabulary
  }
  
  func doInit() async {
    _ = await withErrorReporting {
      try await $words
        .load(
          VocabularyEntry
            .where { $0.vocabularyID.eq(vocabulary.id) }
        )
    }
  }
  
  func plusButtonTapped() {
    isAddEntryPresented = true
  }
}
