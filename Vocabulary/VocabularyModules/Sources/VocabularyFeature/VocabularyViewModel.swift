//
//  VocabularyViewModel.swift
//  VocabularyFeature
//
//  Created by Konstantinos Kolioulis on 8/2/26.
//

import SQLiteData
import VocabularyDB
import Observation
import Shared

@Observable @MainActor
public class VocabularyViewModel {
  
  @ObservationIgnored @Dependency(\.defaultDatabase) var database
  @ObservationIgnored @FetchAll(VocabularyEntry.none) var entries
  var isAddEntryPresented = false
  var isAddFilePresented = false
  var isPracticePresented = false
  let vocabulary: Vocabulary
  var sortOption: SortOption = .defaultSort {
    didSet {
      reloadTask?.cancel()
      reloadTask = Task { await reloadData() }
    }
  }
  var reloadTask: Task<Void, Never>?
  
  public init(vocabulary: Vocabulary) {
    self.vocabulary = vocabulary
  }
  
  func doInit() async {
    _ = await withErrorReporting {
      try await $entries
        .load(
          VocabularyEntry
            .where { $0.vocabularyID.eq(vocabulary.id) }
            .order {
              switch sortOption {
              case .defaultSort:
                $0.rowid
              case .highlights:
                $0.isHighlighted.desc()
              case .alphabetical:
                $0.sourceWord
              }
            },
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
  
  func practiceTapped() {
    isPracticePresented = true
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
  
  private func reloadData() async {
    await doInit()
  }
}
