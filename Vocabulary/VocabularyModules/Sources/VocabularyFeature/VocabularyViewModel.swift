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
  @ObservationIgnored @FetchAll(VocabularyEntry.none) var entries
  var isAddEntryPresented = false
  var isAddFilePresented = false
  let vocabulary: Vocabulary
  
  public init(vocabulary: Vocabulary) {
    self.vocabulary = vocabulary
  }
  
  func doInit() async {
    _ = await withErrorReporting {
      try await $entries
        .load(
          VocabularyEntry
            .where { $0.vocabularyID.eq(vocabulary.id) },
          animation: .default
        )
    }
  }
  
  func addEntryTapped() {
    isAddEntryPresented = true
  }
  
  func addFileTapped() {
    isAddFilePresented = true
  }
  
  func removeFromHighlightsTapped(for entry: VocabularyEntry) {
    changeHighlighted(to: false, for: entry)
  }
  
  func addToHighlightsTapped(for entry: VocabularyEntry) {
    changeHighlighted(to: true, for: entry)
  }
  
  private func changeHighlighted(to value: Bool, for entry: VocabularyEntry) {
    withErrorReporting {
      try database.write { db in
        try VocabularyEntry
          .find(entry.id)
          .update(set: { $0.isHighlighted = value })
          .execute(db)
      }
    }
  }
}
