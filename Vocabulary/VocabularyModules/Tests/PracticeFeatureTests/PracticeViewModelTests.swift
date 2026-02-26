//
//  PracticeViewModelTests.swift
//  VocabularyModules
//
//  Created by Konstantinos Kolioulis on 23/2/26.
//

import DependenciesTestSupport
import Foundation
import SQLiteData
import Testing
import VocabularyDB
import Shared

@testable import PracticeFeature

extension BaseSuite {
  @Suite(
    .dependencies {
      try $0.defaultDatabase.write { db in
        try db.seed {
          Vocabulary.Draft(id: UUID(-1), name: "Spanish", createdAt: Date())
          Vocabulary.Draft(id: UUID(-2), name: "French", createdAt: Date())
          
          // Spanish vocabulary entries
          VocabularyEntry.Draft(
            id: UUID(-10),
            vocabularyID: UUID(-1),
            sourceWord: "hello",
            translatedWord: "hola",
            isHighlighted: false
          )
          VocabularyEntry.Draft(
            id: UUID(-11),
            vocabularyID: UUID(-1),
            sourceWord: "goodbye",
            translatedWord: "adiós",
            isHighlighted: false
          )
          VocabularyEntry.Draft(
            id: UUID(-12),
            vocabularyID: UUID(-1),
            sourceWord: "thank you",
            translatedWord: "gracias",
            isHighlighted: false
          )
          VocabularyEntry.Draft(
            id: UUID(-13),
            vocabularyID: UUID(-1),
            sourceWord: "please",
            translatedWord: "por favor",
            isHighlighted: false
          )
          
          // French vocabulary entries
          VocabularyEntry.Draft(
            id: UUID(-20),
            vocabularyID: UUID(-2),
            sourceWord: "hello",
            translatedWord: "bonjour",
            isHighlighted: false
          )
          VocabularyEntry.Draft(
            id: UUID(-21),
            vocabularyID: UUID(-2),
            sourceWord: "goodbye",
            translatedWord: "au revoir",
            isHighlighted: false
          )
        }
      }
    }
  )
  
  @MainActor
  struct PracticeViewModelTests {
    let vocabulary: Vocabulary
    @Dependency(\.defaultDatabase) var database
    
    init() async throws {
      vocabulary = try await #require(
        _database.wrappedValue.read { db in
          try Vocabulary.find(UUID(-1)).fetchOne(db)
        }
      )
    }
    
    // MARK: - Initialization Tests
    
    @Test func createNewPracticeSession() async throws {
      let model = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model.doInit()
      
      #expect(model.isInitialLoading == false)
      #expect(model.rows.count == 4)
      #expect(model.practice != nil)
      #expect(model.currentIndex == 0)
    }
    
    @Test func createNewPracticeSessionWithShuffledEntries() async throws {
      let model = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model.doInit()
      
      // Verify all entries are present (even if shuffled)
      let sourceWords = Set(model.rows.map { $0.vocabularyEntry.sourceWord })
      #expect(sourceWords == ["hello", "goodbye", "thank you", "please"])
    }
    
    @Test func createNewPracticeOverridesExistingPractice() async throws {
      // Create first practice
      let model1 = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model1.doInit()
      let firstPracticeId = model1.practice?.id
      
      // Create second practice
      let model2 = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model2.doInit()
      let secondPracticeId = model2.practice?.id
      
      // Should have different IDs
      #expect(firstPracticeId != secondPracticeId)
      
      // Verify only one practice exists in database
      let practiceCount = try await database.read { db in
        try Practice
          .where { $0.vocabularyID.eq(vocabulary.id) }
          .fetchCount(db)
      }
      #expect(practiceCount == 1)
    }
    
    @Test func loadExistingPracticeSession() async throws {
      // Create a practice first
      let model1 = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model1.doInit()
      let practiceId = model1.practice!.id
      model1.currentIndex = 2
      await model1.nextEntry() // Save position
      
      // Load it in a new model
      let existingPractice = try await database.read { db in
        try Practice.find(practiceId).fetchOne(db)
      }
      
      let model2 = PracticeViewModel(vocabulary: vocabulary, practice: existingPractice)
      await model2.doInit()
      
      #expect(model2.practice?.id == practiceId)
      #expect(model2.currentIndex == 3)
      #expect(model2.rows.count == 4)
    }
    
    @Test func initialStateWithNewPractice() async throws {
      let model = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model.doInit()
      
      #expect(model.currentIndex == 0)
      #expect(model.isTranslationRevealed == false)
      #expect(model.isAutoRevealEnabled == false)
      #expect(model.hiddenWordProbability == 0.5)
      #expect(model.isRandomnessSettingsPresented == false)
      #expect(model.currentEntry != nil)
    }
    
    // MARK: - Navigation Tests
    
    @Test func nextEntryIncrementsIndex() async throws {
      let model = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model.doInit()
      
      let initialIndex = model.currentIndex
      #expect(initialIndex == 0)
      
      await model.nextEntry()
      
      #expect(model.currentIndex == initialIndex + 1)
      #expect(model.isTranslationRevealed == false)
    }
    
    @Test func previousEntryDecrementsIndex() async throws {
      let model = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model.doInit()
      
      // Move to second entry first
      await model.nextEntry()
      #expect(model.currentIndex == 1)
      
      // Go back
      await model.previousEntry()
      
      #expect(model.currentIndex == 0)
      #expect(model.isTranslationRevealed == false)
    }
    
    @Test func nextEntryResetsRevealedTranslation() async throws {
      let model = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model.doInit()
      
      model.revealTranslation()
      #expect(model.isTranslationRevealed == true)
      
      await model.nextEntry()
      
      // When auto-reveal is disabled, translation should be reset
      #expect(model.isTranslationRevealed == false)
      #expect(model.isAutoRevealEnabled == false)
    }
    
    @Test func previousEntryResetsRevealedTranslation() async throws {
      let model = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model.doInit()
      
      await model.nextEntry()
      model.revealTranslation()
      #expect(model.isTranslationRevealed == true)
      
      await model.previousEntry()
      
      // When auto-reveal is disabled, translation should be reset
      #expect(model.isTranslationRevealed == false)
      #expect(model.isAutoRevealEnabled == false)
    }
    
    @Test func cannotGoNextOnLastEntry() async throws {
      let model = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model.doInit()
      
      // Move to last entry
      while model.canGoNext {
        await model.nextEntry()
      }
      
      #expect(model.canGoNext == false)
      let lastIndex = model.currentIndex
      
      await model.nextEntry() // Should not advance
      
      #expect(model.currentIndex == lastIndex)
    }
    
    @Test func cannotGoPreviousOnFirstEntry() async throws {
      let model = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model.doInit()
      
      #expect(model.canGoPrevious == false)
      
      await model.previousEntry() // Should not decrement
      
      #expect(model.currentIndex == 0)
    }
    
    @Test func canGoPreviousFromSecondEntry() async throws {
      let model = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model.doInit()
      
      #expect(model.canGoPrevious == false)
      
      await model.nextEntry()
      
      #expect(model.canGoPrevious == true)
    }
    
    @Test func canGoNextUntilLastEntry() async throws {
      let model = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model.doInit()
      
      #expect(model.canGoNext == true)
      
      // Jump to third entry (index 2 out of 4)
      model.currentIndex = 2
      
      #expect(model.canGoNext == true)
      
      model.currentIndex = 3
      
      #expect(model.canGoNext == false)
    }
    
    // MARK: - Progress Tests
    
    @Test func progressCalculation() async throws {
      let model = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model.doInit()
      
      #expect(model.progress == 0.25) // 1 / 4
      
      await model.nextEntry()
      #expect(model.progress == 0.5) // 2 / 4
      
      await model.nextEntry()
      #expect(model.progress == 0.75) // 3 / 4
      
      await model.nextEntry()
      #expect(model.progress == 1.0) // 4 / 4
    }
    
    @Test func progressText() async throws {
      let model = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model.doInit()
      
      #expect(model.progressText == "1 / 4")
      
      await model.nextEntry()
      #expect(model.progressText == "2 / 4")
      
      await model.nextEntry()
      #expect(model.progressText == "3 / 4")
      
      await model.nextEntry()
      #expect(model.progressText == "4 / 4")
    }
    
    // MARK: - Translation Reveal Tests
    
    @Test func revealTranslation() async throws {
      let model = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model.doInit()
      
      #expect(model.isTranslationRevealed == false)
      
      model.revealTranslation()
      
      #expect(model.isTranslationRevealed == true)
    }
    
    @Test func revealTranslationDoesNotChangeEntry() async throws {
      let model = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model.doInit()
      
      let initialEntry = model.currentEntry
      
      model.revealTranslation()
      
      #expect(model.currentEntry == initialEntry)
    }
    
    @Test func revealTranslationMultipleTimes() async throws {
      let model = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model.doInit()
      
      model.revealTranslation()
      #expect(model.isTranslationRevealed == true)
      
      model.revealTranslation()
      #expect(model.isTranslationRevealed == true)
    }
    
    // MARK: - Hidden Word Probability Tests
    
    @Test func initialHiddenWordProbability() async throws {
      let model = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model.doInit()
      
      #expect(model.hiddenWordProbability == 0.5)
    }
    
    @Test func applySettings() async throws {
      let model = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model.doInit()
      
      await model.applySettings(probability: 0.8, autoRevealEnabled: false)
      
      #expect(model.hiddenWordProbability == 0.8)
      #expect(model.isAutoRevealEnabled == false)
    }
    
    @Test func applySettingsWithZeroProbability() async throws {
      let model = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model.doInit()
      
      await model.applySettings(probability: 0.0, autoRevealEnabled: false)
      
      #expect(model.hiddenWordProbability == 0.0)
      
      // All source words should be visible
      #expect(model.rows.allSatisfy { !$0.practiceEntry.isOriginalHidden })
    }
    
    @Test func applySettingsWithFullProbability() async throws {
      let model = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model.doInit()
      
      await model.applySettings(probability: 1.0, autoRevealEnabled: false)
      
      #expect(model.hiddenWordProbability == 1.0)
      
      // All source words should be hidden
      #expect(model.rows.allSatisfy { $0.practiceEntry.isOriginalHidden })
    }
    
    @Test func updateHiddenWordProbabilityUpdatesDatabaseEntries() async throws {
      let model = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model.doInit()
      let practiceId = model.practice!.id
      
      await model.applySettings(probability: 1.0, autoRevealEnabled: false)
      
      // Verify in database
      let entries = try await database.read { db in
        try PracticeEntry
          .where { $0.practiceID.eq(practiceId) }
          .fetchAll(db)
      }
      
      #expect(entries.allSatisfy { $0.isOriginalHidden })
    }
    
    @Test func hiddenWordProbabilityPersistsInPractice() async throws {
      let model = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model.doInit()
      let practiceId = model.practice!.id
      
      await model.applySettings(probability: 0.7, autoRevealEnabled: false)
      
      // Verify in practice database
      let practice = try await database.read { db in
        try Practice.find(practiceId).fetchOne(db)
      }
      
      #expect(practice?.hiddenWordProbability == 0.7)
    }
    
    @Test func initializeWithExistingProbability() async throws {
      // Create practice with specific probability
      let model1 = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model1.doInit()
      await model1.applySettings(probability: 0.6, autoRevealEnabled: false)
      let practiceId = model1.practice!.id
      
      // Load in new model
      let practice = try await database.read { db in
        try Practice.find(practiceId).fetchOne(db)
      }
      
      let model2 = PracticeViewModel(vocabulary: vocabulary, practice: practice)
      
      #expect(model2.hiddenWordProbability == 0.6)
    }
    
    // MARK: - Settings Tests
    
    @Test func settingsButtonTapped() async throws {
      let model = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model.doInit()
      
      #expect(model.isRandomnessSettingsPresented == false)
      
      model.settingsButtonTapped()
      
      #expect(model.isRandomnessSettingsPresented == true)
    }
    
    // MARK: - Practice Row Tests
    
    @Test func currentEntry() async throws {
      let model = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model.doInit()
      
      let entry = model.currentEntry
      #expect(entry != nil)
      #expect(entry?.vocabularyEntry.sourceWord.isEmpty == false)
    }
    
    @Test func currentEntryChangesWithNavigation() async throws {
      let model = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model.doInit()
      
      let firstEntry = model.currentEntry
      
      await model.nextEntry()
      
      let secondEntry = model.currentEntry
      
      #expect(firstEntry?.practiceEntry.id != secondEntry?.practiceEntry.id)
    }
    
    @Test func practiceRowVisibleWord() async throws {
      let model = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model.doInit()
      
      let row = model.currentEntry!
      
      if row.practiceEntry.isOriginalHidden {
        #expect(row.visibleWord == row.vocabularyEntry.translatedWord)
      } else {
        #expect(row.visibleWord == row.vocabularyEntry.sourceWord)
      }
    }
    
    @Test func practiceRowHiddenWord() async throws {
      let model = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model.doInit()
      
      let row = model.currentEntry!
      
      if row.practiceEntry.isOriginalHidden {
        #expect(row.hiddenWord == row.vocabularyEntry.sourceWord)
      } else {
        #expect(row.hiddenWord == row.vocabularyEntry.translatedWord)
      }
    }
    
    // MARK: - Edge Cases Tests
    
    @Test func navigationMultipleTimes() async throws {
      let model = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model.doInit()
      
      await model.nextEntry()
      await model.nextEntry()
      await model.previousEntry()
      await model.nextEntry()
      
      #expect(model.currentIndex == 2)
    }
    
    @Test func positionPersistenceAfterNavigation() async throws {
      let model = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model.doInit()
      let practiceId = model.practice!.id
      
      await model.nextEntry()
      await model.nextEntry()
      await model.previousEntry()
      
      #expect(model.currentIndex == 1)
      
      // Verify in database
      let practice = try await database.read { db in
        try Practice.find(practiceId).fetchOne(db)
      }
      
      #expect(practice?.lastStoppedPosition == 1)
    }
    
    @Test func singleEntryVocabulary() async throws {
      // Create vocabulary with single entry
      try await database.write { db in
        try db.seed {
          Vocabulary.Draft(id: UUID(-50), name: "Single", createdAt: Date())
          VocabularyEntry.Draft(
            id: UUID(-51),
            vocabularyID: UUID(-50),
            sourceWord: "one",
            translatedWord: "uno",
            isHighlighted: false
          )
        }
      }
      
      let singleVocab = try await database.read { db in
        try Vocabulary.find(UUID(-50)).fetchOne(db)
      }!
      
      let model = PracticeViewModel(vocabulary: singleVocab, practice: nil)
      await model.doInit()
      
      #expect(model.rows.count == 1)
      #expect(model.canGoNext == false)
      #expect(model.canGoPrevious == false)
      #expect(model.progress == 1.0)
    }
    
    @Test func differentVocabularyPracticesAreIndependent() async throws {
      let spanishVocab = try await database.read { db in
        try Vocabulary.find(UUID(-1)).fetchOne(db)
      }!
      
      let frenchVocab = try await database.read { db in
        try Vocabulary.find(UUID(-2)).fetchOne(db)
      }!
      
      let spanishModel = PracticeViewModel(vocabulary: spanishVocab, practice: nil)
      await spanishModel.doInit()
      
      let frenchModel = PracticeViewModel(vocabulary: frenchVocab, practice: nil)
      await frenchModel.doInit()
      
      await spanishModel.nextEntry()
      await spanishModel.nextEntry()
      
      // French should still be at first entry
      #expect(spanishModel.currentIndex == 2)
      #expect(frenchModel.currentIndex == 0)
      #expect(spanishModel.practice?.id != frenchModel.practice?.id)
    }
    
    @Test func translationRevealStateIndependentPerEntry() async throws {
      let model = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model.doInit()
      
      model.revealTranslation()
      #expect(model.isTranslationRevealed == true)
      
      // Moving resets the state (when auto-reveal is disabled)
      await model.nextEntry()
      #expect(model.isTranslationRevealed == false)
      #expect(model.isAutoRevealEnabled == false)
      
      // Reveal again
      model.revealTranslation()
      #expect(model.isTranslationRevealed == true)
      
      // Go back
      await model.previousEntry()
      #expect(model.isTranslationRevealed == false)
    }
    
    // MARK: - Auto Reveal Tests
    
    @Test func applySettingsWithAutoRevealEnabled() async throws {
      let model = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model.doInit()
      
      #expect(model.isAutoRevealEnabled == false)
      #expect(model.isTranslationRevealed == false)
      
      await model.applySettings(probability: 0.5, autoRevealEnabled: true)
      
      #expect(model.isAutoRevealEnabled == true)
      #expect(model.isTranslationRevealed == true)
    }
    
    @Test func autoRevealMaintainsStateOnNavigation() async throws {
      let model = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model.doInit()
      
      await model.applySettings(probability: 0.5, autoRevealEnabled: true)
      #expect(model.isTranslationRevealed == true)
      
      await model.nextEntry()
      
      // Translation should remain revealed when auto-reveal is enabled
      #expect(model.isTranslationRevealed == true)
      #expect(model.isAutoRevealEnabled == true)
      
      await model.previousEntry()
      
      #expect(model.isTranslationRevealed == true)
    }
    
    @Test func disablingAutoRevealHidesTranslation() async throws {
      let model = PracticeViewModel(vocabulary: vocabulary, practice: nil)
      await model.doInit()
      
      await model.applySettings(probability: 0.5, autoRevealEnabled: true)
      #expect(model.isTranslationRevealed == true)
      
      // Disable auto-reveal
      await model.applySettings(probability: 0.5, autoRevealEnabled: false)
      
      #expect(model.isAutoRevealEnabled == false)
      #expect(model.isTranslationRevealed == false)
    }
  }
}

@Suite(
  .dependencies {
    $0.uuid = .incrementing
    try $0.bootstrapDatabase()
  }
)
struct BaseSuite {}
