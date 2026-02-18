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
  @ObservationIgnored @FetchAll(Practice.none) var pendingPractices
  var practiceEntryCounts: [Practice.ID: Int] = [:]
  @ObservationIgnored var firstInitExecuted = false
  var isAddEntryPresented = false
  var isAddFilePresented = false
  var isPracticePresented = false
  var isLoading = false
  let vocabulary: Vocabulary
  var sortOption: SortOption = .defaultSort {
    didSet {
      reloadTask?.cancel()
      reloadTask = Task {
        try? await Task.sleep(for: .milliseconds(100))
        if Task.isCancelled { return }
        await reloadData()
      }
    }
  }
  var reloadTask: Task<Void, Never>?
  
  public init(vocabulary: Vocabulary) {
    self.vocabulary = vocabulary
  }
  
  func doInit() async {
    showLoadingOnFirstInit(true)
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
    
    _ = await withErrorReporting {
      try await $pendingPractices.load(
        Practice.where { $0.vocabularyID.eq(vocabulary.id) },
        animation: .default
      )
    }
    
    _ = await withErrorReporting {
      let practiceIDs = pendingPractices.map(\.id)
      let counts = try await database.read { db in
        var dict: [Practice.ID: Int] = [:]
        for id in practiceIDs {
          let count = try PracticeEntry
            .where { $0.practiceID == id }
            .fetchCount(db)
          dict[id] = count
        }
        return dict
      }
      self.practiceEntryCounts = counts
    }
    
    showLoadingOnFirstInit(false)
    firstInitExecuted = true
  }
  
  private func showLoadingOnFirstInit(_ loading: Bool) {
    if firstInitExecuted { return }
    isLoading = loading
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
  
  func deletePractice(_ practice: Practice) {
    withErrorReporting {
      try database.write { db in
        try Practice.find(practice.id).delete().execute(db)
      }
    }
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

