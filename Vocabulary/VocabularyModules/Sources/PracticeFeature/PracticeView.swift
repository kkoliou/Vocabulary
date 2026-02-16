//
//  PracticeView.swift
//  VocabularyModules
//
//  Created by Konstantinos Kolioulis on 15/2/26.
//

import SwiftUI
import VocabularyDB
import SQLiteData

public struct PracticeView: View {
  
  @Environment(\.dismiss) private var dismiss
  @State var viewModel: PracticeViewModel
  
  public init(vocabulary: Vocabulary, entries: [VocabularyEntry]) {
    _viewModel = State(
      wrappedValue: PracticeViewModel(
        vocabulary: vocabulary,
        entries: entries
      )
    )
  }
  
  public var body: some View {
    VStack(spacing: 0) {
      ProgressBarView(
        progressText: viewModel.progressText,
        vocabularyName: viewModel.vocabulary.name,
        progress: viewModel.progress
      )
      
      if let entry = viewModel.currentEntry {
        VocabularyCardView(
          practiceEntry: entry,
          isTranslationRevealed: viewModel.isTranslationRevealed,
          onRevealTranslation: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
              viewModel.revealTranslation()
            }
          }
        )
      } else {
        EmptyStateView()
      }
      
      NavigationControlsView(
        canGoPrevious: viewModel.canGoPrevious,
        canGoNext: viewModel.canGoNext,
        currentIndex: viewModel.currentIndex,
        totalCount: viewModel.entries.count,
        onPrevious: { viewModel.previousEntry() },
        onNext: { viewModel.nextEntry() }
      )
    }
    .navigationTitle("Practice")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button("Done") {
          dismiss()
        }
      }
    }
    .task {
      await viewModel.doInit()
    }
  }
}

#Preview {
  let vocab = prepareDependencies {
    try! $0.bootstrapDatabase()
    try! $0.defaultDatabase.seedForPreview()
    return try! $0.defaultDatabase.read { db in
      try Vocabulary.fetchOne(db)!
    }
  }

  NavigationStack {
    PracticeView(vocabulary: vocab, entries: [])
  }
}


enum HiddenWord {
  case original
  case translated
}

struct PracticeEntry {
  let entry: VocabularyEntry
  let hiddenWord: HiddenWord
  
  var visibleWord: String {
    hiddenWord == .original ? entry.translatedWord : entry.sourceWord
  }
  
  var hiddenWordText: String {
    hiddenWord == .original ? entry.sourceWord : entry.translatedWord
  }
}

@Observable @MainActor
class PracticeViewModel {
  
  let vocabulary: Vocabulary
  let entries: [VocabularyEntry]
  var practiceEntries = [PracticeEntry]()
  var currentIndex: Int = 0
  var isTranslationRevealed: Bool = false
  var isLoading = false
  
  public init(vocabulary: Vocabulary, entries: [VocabularyEntry]) {
    self.vocabulary = vocabulary
    self.entries = entries
  }
  
  func doInit() async {
    isLoading = true
    practiceEntries = await setupData()
    isLoading = false
  }
  
  @concurrent
  private func setupData() async -> [PracticeEntry]{
    entries.shuffled().map { entry in
      PracticeEntry(
        entry: entry,
        hiddenWord: Bool.random() ? .original : .translated
      )
    }
  }
  
  var currentEntry: PracticeEntry? {
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
}
