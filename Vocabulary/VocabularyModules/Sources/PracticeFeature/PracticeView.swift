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
  @State private var isRandomnessSettingsPresented = false
  
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
            Utilities.triggerLightHaptic()
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
        Button {
          viewModel.settingsButtonTapped()
        } label: {
          Image(systemName: "gear")
        }
      }
    }
    .vSheet(isPresented: $viewModel.isRandomnessSettingsPresented) {
      RandomnessSettingsView(
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

struct RandomnessSettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var probability: Double
  let onApply: (Double) -> Void
  
  init(
    probability: Double,
    onApply: @escaping (Double) -> Void
  ) {
    _probability = State(initialValue: probability)
    self.onApply = onApply
  }
  
  var body: some View {
    NavigationStack {
      Form {
        Section {
          VStack(alignment: .leading, spacing: 8) {
            Slider(value: $probability, in: 0...1, step: 0.1)
            Text(probabilityLabel)
              .font(AppTypography.subheadline)
              .foregroundStyle(.secondary)
          }
          .padding(.vertical, 8)
        } header: {
          Text("Hidden Word Randomness")
        } footer: {
          Text("Adjust the probability that the original word (vs translation) will be hidden. 50% means equal chance for each.")
        }
      }
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(
            action: {
              onApply(probability)
              let generator = UIImpactFeedbackGenerator(style: .light)
              generator.impactOccurred()
              dismiss()
            },
            label: {
              Image(systemName: "checkmark")
            }
          )
        }
      }
    }
  }
  
  private var probabilityLabel: String {
    let percent = Int(probability * 100)
    switch percent {
    case 0:
      return "Always hide translation"
    case 100:
      return "Always hide original"
    default:
      return "\(percent)% chance to hide original"
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
  private func setupData(probability: Double) async -> [PracticeEntry] {
    entries.shuffled().map { entry in
      PracticeEntry(
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
  ) async -> [PracticeEntry] {
    await practiceEntries.map { practiceEntry in
      PracticeEntry(
        entry: practiceEntry.entry,
        hiddenWord: Double.random(in: 0..<1) < probability ? .original : .translated
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
  
  func settingsButtonTapped() {
    isRandomnessSettingsPresented = true
  }
}
