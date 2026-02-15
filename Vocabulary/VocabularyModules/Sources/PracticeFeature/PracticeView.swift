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
          entry: entry,
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


@Observable @MainActor
class PracticeViewModel {
  
  let vocabulary: Vocabulary
  let entries: [VocabularyEntry]
  var currentIndex: Int = 0
  var isTranslationRevealed: Bool = false
  
  public init(vocabulary: Vocabulary, entries: [VocabularyEntry]) {
    self.vocabulary = vocabulary
    self.entries = entries
  }
  
  func doInit() async {
//    _ = await withErrorReporting {
//      try await $entries
//        .load(
//          VocabularyEntry
//            .where { $0.vocabularyID.eq(vocabulary.id) },
//          animation: .default
//        )
//    }
  }
  
  var currentEntry: VocabularyEntry? {
    guard !entries.isEmpty, currentIndex < entries.count else { return nil }
    return entries[currentIndex]
  }
  
  var progress: Double {
    guard !entries.isEmpty else { return 0 }
    return Double(currentIndex + 1) / Double(entries.count)
  }
  
  var progressText: String {
    guard !entries.isEmpty else { return "0 / 0" }
    return "\(currentIndex + 1) / \(entries.count)"
  }
  
  var canGoPrevious: Bool {
    currentIndex > 0
  }
  
  var canGoNext: Bool {
    currentIndex < entries.count - 1
  }
  
  //  init(vocabulary: Vocabulary, entries: [VocabularyEntry]) {
  //    self.vocabulary = vocabulary
  //    self.entries = entries.shuffled()
  //  }
  
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
