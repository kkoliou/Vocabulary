//
//  PracticeViewModel.swift
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
  var rows = [PracticeRow]()
  let vocabulary: Vocabulary
  var practice: Practice?
  var currentIndex: Int = 0
  var isTranslationRevealed: Bool = false
  var isInitialLoading = false
  var hiddenWordProbability: Double = 0.5
  var isRandomnessSettingsPresented = false
  private var saveTask: Task<Void, Never>?
  
  public init(
    vocabulary: Vocabulary,
    practice: Practice?
  ) {
    self.vocabulary = vocabulary
    self.practice = practice
    if let practice = practice {
      self.hiddenWordProbability = practice.hiddenWordProbability
    }
  }
  
  func doInit() async {
    isInitialLoading = true
    if practice != nil {
      await initPracticeData()
    } else {
      await createNewPractice()
      await initPracticeData()
    }
    isInitialLoading = false
  }
  
  private func initPracticeData() async {
    if let practice = practice {
      _ = await withErrorReporting {
        let rows = try await database.read { db in
          try PracticeEntry
            .where { $0.practiceID.eq(practice.id) }
            .join(VocabularyEntry.all) { $0.vocabularyEntryID.eq($1.id) }
            .order(by: \.position)
            .select { PracticeRow.Columns(practiceEntry: $0, vocabularyEntry: $1) }
            .fetchAll(db)
        }
        self.rows = rows
      }
      if let lastStoppedPosition = practice.lastStoppedPosition,
         lastStoppedPosition < rows.count {
        currentIndex = lastStoppedPosition
      }
    }
  }
  
  private func createNewPractice() async {
    let probability = hiddenWordProbability
    await withErrorReporting {
      let entries = try await database.read { db in
        try VocabularyEntry
          .where { $0.vocabularyID.eq(vocabulary.id) }
          .fetchAll(db)
      }
      
      let shuffledEntries = entries.shuffled()
      
      let practiceId = UUID()
      try await database.write { db in
        
        // Override any other practice of this vocab
        try Practice.where { $0.vocabularyID == vocabulary.id }
          .delete()
          .execute(db)
        
        try Practice.insert {
          Practice.Draft(
            id: practiceId,
            vocabularyID: vocabulary.id,
            hiddenWordProbability: probability,
            createdAt: .now,
            lastStoppedVocabularyEntryID: nil,
            lastStoppedPosition: 0
          )
        }
        .execute(db)
        
        try db.seed {
          for (index, entry) in shuffledEntries.enumerated() {
            PracticeEntry.Draft(
              practiceID: practiceId,
              vocabularyEntryID: entry.id,
              position: index,
              isOriginalHidden: Double.random(in: 0..<1) < probability
            )
          }
        }
      }
      
      practice = try await database.read { db in
        try Practice
          .where { $0.vocabularyID.eq(vocabulary.id) }
          .fetchOne(db)
      }
    }
  }
  
  private func savePractice() async {
    guard let practice = practice else { return }
    
    let currentVocabularyEntryID: VocabularyEntry.ID?
    if let currentRow = currentEntry {
      currentVocabularyEntryID = currentRow.vocabularyEntry.id
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
  
  func applyHiddenWordProbability(_ probability: Double) async {
    hiddenWordProbability = probability
    await updateEntriesWithHiddenWordProbability(probability, database: database, rows: rows)
    await savePractice()
    await initPracticeData()
  }
  
  @concurrent
  private func updateEntriesWithHiddenWordProbability(
    _ probability: Double,
    database: DatabaseWriter,
    rows: [PracticeRow]
  ) async {
    withErrorReporting {
      try database.write { db in
        for row in rows {
          try PracticeEntry
            .find(row.practiceEntry.id)
            .update(
              set: {
                $0.isOriginalHidden = Double.random(in: 0..<1) < probability
              }
            )
            .execute(db)
        }
      }
    }
  }
  
  var currentEntry: PracticeRow? {
    guard !rows.isEmpty, currentIndex < rows.count else { return nil }
    return rows[currentIndex]
  }
  
  var progress: Double {
    guard !rows.isEmpty else { return 0 }
    return Double(currentIndex + 1) / Double(rows.count)
  }
  
  var progressText: String {
    guard !rows.isEmpty else { return "0 / 0" }
    return "\(currentIndex + 1) / \(rows.count)"
  }
  
  var canGoPrevious: Bool {
    currentIndex > 0
  }
  
  var canGoNext: Bool {
    currentIndex < rows.count - 1
  }
  
  func revealTranslation() {
    isTranslationRevealed = true
  }
  
  func nextEntry() async {
    guard canGoNext else { return }
    currentIndex += 1
    isTranslationRevealed = false
    await savePractice()
  }
  
  func previousEntry() async {
    guard canGoPrevious else { return }
    currentIndex -= 1
    isTranslationRevealed = false
    await savePractice()
  }
  
  func settingsButtonTapped() {
    isRandomnessSettingsPresented = true
  }
}

@Selection struct PracticeRow: Equatable {
  let practiceEntry: PracticeEntry
  let vocabularyEntry: VocabularyEntry
  
  var visibleWord: String {
    practiceEntry.isOriginalHidden ? vocabularyEntry.translatedWord : vocabularyEntry.sourceWord
  }
  
  var hiddenWord: String {
    practiceEntry.isOriginalHidden ? vocabularyEntry.sourceWord : vocabularyEntry.translatedWord
  }
}
