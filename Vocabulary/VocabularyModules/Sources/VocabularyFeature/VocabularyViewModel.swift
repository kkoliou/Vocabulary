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
import Sharing
import Foundation
import PracticeFeature

@Observable @MainActor
public class VocabularyViewModel {
  
  @Selection struct PendingPracticeRow {
    var practice: Practice
    var entriesCount: Int
  }
  
  @ObservationIgnored @Dependency(\.defaultDatabase) var database
  @ObservationIgnored @FetchAll(VocabularyEntry.none) var entries
  @ObservationIgnored @FetchAll(PendingPracticeRow.none) var pendingPracticesRows
  @ObservationIgnored @FetchAll(VocabularyEntry.where(\.isHighlighted)) var highlightedEntries
  @ObservationIgnored var firstInitExecuted = false
  var isAddEntryPresented = false
  var isAddFilePresented = false
  var isPracticePresented = false
  var isCreatePracticeAlertPresented = false
  var isEditEntryPresented = false
  var isLoading = false
  var searchText = ""
  var entryToEdit: VocabularyEntry?
  let vocabulary: Vocabulary
  @ObservationIgnored @Shared var sortOption: SortOption
  var reloadTask: Task<Void, Never>?
  @ObservationIgnored var selectedPracticeScope: PracticeScope = .all
  var isPracticeScopeMenuPresented = false
  
  public init(vocabulary: Vocabulary) {
    self.vocabulary = vocabulary
    _sortOption = Shared(wrappedValue: .defaultSort, .appStorage("sortOption_\(vocabulary.id)"))
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
  
  func changeSortOption(to option: SortOption) async {
    $sortOption.withLock { $0 = option }
    reloadTask?.cancel()
    reloadTask = Task {
      try? await Task.sleep(for: .milliseconds(100))
      if Task.isCancelled { return }
      try? await loadEntries()
    }
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
  
  func removeFromHighlightsTapped(for entry: VocabularyEntry) async {
    await changeHighlighted(to: false, for: entry)
  }
  
  func addToHighlightsTapped(for entry: VocabularyEntry) async {
    await changeHighlighted(to: true, for: entry)
  }
  
  func practiceTapped() {
    if !highlightedEntries.isEmpty {
      isPracticeScopeMenuPresented = true
    } else {
      startPractice(scope: .all)
    }
  }
  
  func confirmCreateNewPractice() {
    isCreatePracticeAlertPresented = false
    startPractice(scope: selectedPracticeScope, checkForPendingPractices: false)
  }
  
  func startPractice(scope: PracticeScope, checkForPendingPractices: Bool = true) {
    selectedPracticeScope = scope
    if checkForPendingPractices && pendingPracticesRows.count > 0 {
      isCreatePracticeAlertPresented = true
      return
    }
    isPracticeScopeMenuPresented = false
    isPracticePresented = true
  }
  
  func deletePractices(at offsets: IndexSet) {
    withErrorReporting {
      try database.write { db in
        try Practice.find(offsets.map { pendingPracticesRows[$0].practice.id })
          .delete()
          .execute(db)
      }
    }
  }
  
  func deleteEntry(_ entry: VocabularyEntry) {
    withErrorReporting {
      try database.write { db in
        try VocabularyEntry
          .find(entry.id)
          .delete()
          .execute(db)
      }
    }
  }
  
  func editEntry(_ entry: VocabularyEntry) {
    entryToEdit = entry
    isEditEntryPresented = true
  }
  
  private func changeHighlighted(to value: Bool, for entry: VocabularyEntry) async {
    await withErrorReporting {
      try await database.write { db in
        try VocabularyEntry
          .find(entry.id)
          .update(set: { $0.isHighlighted = value })
          .execute(db)
      }
    }
  }
  
  var filteredEntries: [VocabularyEntry] {
    if searchText.isEmpty {
      return entries
    }
    
    let lowercasedSearch = searchText.lowercased()
    return entries.filter { entry in
      entry.sourceWord.lowercased().contains(lowercasedSearch) ||
      entry.translatedWord.lowercased().contains(lowercasedSearch)
    }
  }
}
