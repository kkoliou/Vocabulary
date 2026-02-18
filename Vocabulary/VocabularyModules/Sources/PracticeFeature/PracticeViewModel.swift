//
//  File.swift
//  VocabularyModules
//
//  Created by Konstantinos Kolioulis on 16/2/26.
//

import VocabularyDB
import SQLiteData
import Shared
import Observation
import Foundation

@Observable @MainActor
class PracticeViewModel {
  @ObservationIgnored @Dependency(\.defaultDatabase) var database
  let vocabulary: Vocabulary
  let entries: [VocabularyEntry]
  let practice: Practice?
  var practiceEntries = [PracticeData]()
  var currentIndex: Int = 0
  var isTranslationRevealed: Bool = false
  var isLoading = false
  var hiddenWordProbability: Double = 0.5
  var isRandomnessSettingsPresented = false
  
  public init(vocabulary: Vocabulary, entries: [VocabularyEntry], practice: Practice? = nil) {
    self.vocabulary = vocabulary
    self.entries = entries
    self.practice = practice
    if let practice = practice {
      self.hiddenWordProbability = practice.hiddenWordProbability
    }
  }
  
  func doInit() async {
    isLoading = true
    if let practice = practice {
      // Load existing practice from persisted PracticeEntry snapshot
      _ = await withErrorReporting {
        let loaded: [PracticeData] = try database.read { db in
          let rows = try PracticeEntry
            .where { $0.practiceID == practice.id }
            .order(by: \.position)
            .fetchAll(db)
          return try rows.compactMap { pe in
            let entry = try VocabularyEntry.find(pe.vocabularyEntryID).fetchOne(db)
            guard let entry else { return nil }
            return PracticeData(
              entry: entry,
              hiddenWord: pe.isOriginalHidden ? .original : .translated
            )
          }
        }
        self.practiceEntries = loaded
      }
      // Restore position to last stopped position if available
      if let lastStoppedPosition = practice.lastStoppedPosition,
         lastStoppedPosition < practiceEntries.count {
        currentIndex = lastStoppedPosition
      }
    } else {
      // New practice, create it in database
      practiceEntries = await setupData(probability: hiddenWordProbability)
      await createNewPractice()
    }
    isLoading = false
  }
  
  private func createNewPractice() async {
    withErrorReporting {
      let practiceId = UUID()
      try database.write { db in
        try Practice.insert {
          Practice.Draft(
            id: practiceId,
            vocabularyID: vocabulary.id,
            hiddenWordProbability: hiddenWordProbability,
            createdAt: .now,
            lastStoppedVocabularyEntryID: nil,
            lastStoppedPosition: 0
          )
        }
        .execute(db)

        for (index, practiceEntry) in practiceEntries.enumerated() {
          try PracticeEntry.insert {
            PracticeEntry.Draft(
              practiceID: practiceId,
              vocabularyEntryID: practiceEntry.entry.id,
              position: index,
              isOriginalHidden: practiceEntry.hiddenWord == .original
            )
          }
          .execute(db)
        }
      }
    }
  }
  
  private func savePractice() async {
    guard let practice = practice else { return }
    
    let currentVocabularyEntryID: VocabularyEntry.ID?
    if let currentEntry = currentEntry {
      currentVocabularyEntryID = currentEntry.entry.id
    } else {
      currentVocabularyEntryID = nil
    }
    
    withErrorReporting {
      try database.write { db in
        try Practice
          .find(practice.id)
          .update(
            set: {
              $0.hiddenWordProbability = hiddenWordProbability
              $0.lastStoppedVocabularyEntryID = currentVocabularyEntryID
              $0.lastStoppedPosition = currentIndex
            }
          )
          .execute(db)
      }
    }
  }
  
  @concurrent
  private func setupData(probability: Double) async -> [PracticeData] {
    entries.shuffled().map { entry in
      PracticeData(
        entry: entry,
        hiddenWord: Double.random(in: 0..<1) < probability ? .original : .translated
      )
    }
  }
  
  func applyHiddenWordProbability(_ probability: Double) async {
    hiddenWordProbability = probability
    practiceEntries = await setupEntriesWithHiddenWordProbability(probability)
    await savePractice()
  }
  
  @concurrent
  private func setupEntriesWithHiddenWordProbability(
    _ probability: Double
  ) async -> [PracticeData] {
    await practiceEntries.map { practiceEntry in
      PracticeData(
        entry: practiceEntry.entry,
        hiddenWord: Double.random(in: 0..<1) < probability ? .original : .translated
      )
    }
  }
  
  var currentEntry: PracticeData? {
    guard !practiceEntries.isEmpty, currentIndex < practiceEntries.count
    else { return nil }
    return practiceEntries[currentIndex]
  }
  
  var progress: Double {
    guard !practiceEntries.isEmpty else { return 0 }
    return Double(currentIndex + 1) / Double(practiceEntries.count)
  }
  
  var progressText: String {
    guard !practiceEntries.isEmpty else { return "0 / 0" }
    return "\(currentIndex + 1) / \(practiceEntries.count)"
  }
  
  var canGoPrevious: Bool {
    currentIndex > 0
  }
  
  var canGoNext: Bool {
    currentIndex < practiceEntries.count - 1
  }
  
  func revealTranslation() {
    isTranslationRevealed = true
  }
  
  func nextEntry() {
    guard canGoNext else { return }
    currentIndex += 1
    isTranslationRevealed = false
    Task {
      await savePractice()
    }
  }
  
  func previousEntry() {
    guard canGoPrevious else { return }
    currentIndex -= 1
    isTranslationRevealed = false
    Task {
      await savePractice()
    }
  }
  
  func settingsButtonTapped() {
    isRandomnessSettingsPresented = true
  }
}

enum HiddenWord {
  case original
  case translated
}

struct PracticeData {
  let entry: VocabularyEntry
  let hiddenWord: HiddenWord
  
  var visibleWord: String {
    hiddenWord == .original ? entry.translatedWord : entry.sourceWord
  }
  
  var hiddenWordText: String {
    hiddenWord == .original ? entry.sourceWord : entry.translatedWord
  }
}
