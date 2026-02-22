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
  
  @Selection struct PendingPracticeRow {
    var practice: Practice
    var entriesCount: Int
  }
  
  @ObservationIgnored @Dependency(\.defaultDatabase) var database
  @ObservationIgnored @FetchAll(VocabularyEntry.none) var entries
  @ObservationIgnored @FetchAll(PendingPracticeRow.none) var pendingPracticesRows
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
      try await loadEntries()
      try await loadPendingPractices()
      try await removeCompletedPractices()
    }
    showLoadingOnFirstInit(false)
    firstInitExecuted = true
  }
  
  private func loadEntries() async throws {
    try await $entries.load(
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
  
  private func loadPendingPractices() async throws {
    try await $pendingPracticesRows.load(
      Practice
        .where { $0.vocabularyID.eq(vocabulary.id) }
        .group(by: \.id)
        .leftJoin(PracticeEntry.all) { $0.id.eq($1.practiceID) }
        .select { PendingPracticeRow.Columns(practice: $0, entriesCount: $1.count()) },
      animation: .default
    )
  }
  
  private func removeCompletedPractices() async throws {
    let completedPracticeRows = pendingPracticesRows.filter { row in
      let total = row.entriesCount
      guard total > 0 else { return true }
      let last = row.practice.lastStoppedPosition ?? -1
      return last >= total - 1
    }
    
    guard !completedPracticeRows.isEmpty else { return }
    
    try await database.write { db in
      for row in completedPracticeRows {
        try Practice.find(row.practice.id)
          .delete()
          .execute(db)
      }
    }
    
    try await loadPendingPractices()
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
  
  func deletePractice(_ practiceRow: PendingPracticeRow) {
    withErrorReporting {
      try database.write { db in
        try Practice.find(practiceRow.practice.id).delete().execute(db)
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

