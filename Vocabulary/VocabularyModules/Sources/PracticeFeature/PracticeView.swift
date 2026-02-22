//
//  PracticeView.swift
//  VocabularyModules
//
//  Created by Konstantinos Kolioulis on 15/2/26.
//

import SwiftUI
import VocabularyDB
import SQLiteData
import Shared

public struct PracticeView: View {
  
  @Environment(\.dismiss) private var dismiss
  @State var viewModel: PracticeViewModel
  
  public init(vocabulary: Vocabulary, practice: Practice? = nil) {
    _viewModel = State(
      wrappedValue: PracticeViewModel(
        vocabulary: vocabulary,
        practice: practice
      )
    )
  }
  
  public var body: some View {
    VStack(spacing: 0) {
      if viewModel.isInitialLoading {
        ProgressView()
      } else if let entry = viewModel.currentEntry {
        ProgressBarView(
          progressText: viewModel.progressText,
          vocabularyName: viewModel.vocabulary.name,
          progress: viewModel.progress
        )
        VocabularyCardView(
          practiceData: entry,
          isTranslationRevealed: viewModel.isTranslationRevealed,
          onRevealTranslation: {
            Utilities.triggerLightHaptic()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
              viewModel.revealTranslation()
            }
          }
        )
        NavigationControlsView(
          canGoPrevious: viewModel.canGoPrevious,
          canGoNext: viewModel.canGoNext,
          currentIndex: viewModel.currentIndex,
          totalCount: viewModel.rows.count,
          onPrevious: {
            Task {
              await viewModel.previousEntry()
            }
          },
          onNext: {
            Task {
              await viewModel.nextEntry()
            }
          }
        )
      } else {
        EmptyStateView()
      }
    }
    .navigationTitle(Strings.localized("Practice"))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          viewModel.settingsButtonTapped()
        } label: {
          Image(systemName: "gear")
        }
      }
    }
    .vSheet(isPresented: $viewModel.isRandomnessSettingsPresented) {
      PracticeSettingsView(
        probability: viewModel.hiddenWordProbability,
        onApply: { newProbability in
          Task {
            await viewModel.applyHiddenWordProbability(newProbability)
          }
        }
      )
      .presentationDetents([.medium])
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
    PracticeView(vocabulary: vocab)
  }
}
