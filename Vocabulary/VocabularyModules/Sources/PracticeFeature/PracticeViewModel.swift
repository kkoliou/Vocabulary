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

@Observable @MainActor
class PracticeViewModel {
  let vocabulary: Vocabulary
  let entries: [VocabularyEntry]
  var practiceEntries = [PracticeData]()
  var currentIndex: Int = 0
  var isTranslationRevealed: Bool = false
  var isLoading = false
  var hiddenWordProbability: Double = 0.5
  var isRandomnessSettingsPresented = false
  
  public init(vocabulary: Vocabulary, entries: [VocabularyEntry]) {
    self.vocabulary = vocabulary
    self.entries = entries
  }
  
  func doInit() async {
    isLoading = true
    practiceEntries = await setupData(probability: hiddenWordProbability)
    isLoading = false
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
  }
  
  func previousEntry() {
    guard canGoPrevious else { return }
    currentIndex -= 1
    isTranslationRevealed = false
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
