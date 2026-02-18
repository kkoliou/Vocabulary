//
//  VocabularyView.swift
//  VocabularyFeature
//
//  Created by Konstantinos Kolioulis on 7/2/26.
//

import SwiftUI
import SQLiteData
import VocabularyDB
import Shared
import PracticeFeature

public struct VocabularyView: View {
  
  @State var viewModel: VocabularyViewModel
  
  public init(vocabulary: Vocabulary) {
    _viewModel = State(wrappedValue: VocabularyViewModel(vocabulary: vocabulary))
  }
  
  public var body: some View {
    Form {
      if viewModel.isLoading {
        HStack() {
          Spacer()
          ProgressView()
          Spacer()
        }
      } else {
        List {
          if !viewModel.pendingPracticesRows.isEmpty {
            practicesSectionView
          }
          if !viewModel.entries.isEmpty {
            vocabularySectionView
          }
        }
      }
    }
    .navigationTitle(viewModel.vocabulary.name)
    .toolbar {
      ToolbarItemGroup(placement: .primaryAction) {
        Menu {
          Picker(Strings.localized("Sort By"), selection: $viewModel.sortOption) {
            ForEach([SortOption.defaultSort, .highlights, .alphabetical], id: \.self) { option in
              Label(option.title, systemImage: option.icon)
                .font(AppTypography.body)
                .tag(option)
            }
          }
          .pickerStyle(.inline)
        } label: {
          Label(Strings.localized("Sort"), systemImage: "arrow.up.arrow.down")
        }
        
        Menu {
          Button(Strings.localized("Add Entry"), systemImage: "plus") {
            viewModel.addEntryTapped()
          }
          Button(Strings.localized("Import File"), systemImage: "tray.and.arrow.down") {
            viewModel.addFileTapped()
          }
        } label: {
          Label(Strings.localized("Add"), systemImage: "plus")
        }
        
        Button(
          action: {
            viewModel.practiceTapped()
          },
          label: {
            Image(systemName: "brain.head.profile")
          }
        )
        
      }
    }
    .task {
      await viewModel.doInit()
    }
    .vSheet(isPresented: $viewModel.isAddEntryPresented) {
      VocabularyEntryAddView(vocabulary: viewModel.vocabulary)
        .largePresentationDetents()
    }
    .vSheet(isPresented: $viewModel.isAddFilePresented) {
      VocabularyEntriesAddView(vocabulary: viewModel.vocabulary)
        .defaultPresentationDetents()
    }
    .navigationDestination(
      isPresented: $viewModel.isPracticePresented,
      destination: {
        PracticeView(
          vocabulary: viewModel.vocabulary,
          entries: viewModel.entries,
          practice: nil
        )
      }
    )
  }
  
  private var practicesSectionView: some View {
    Section(header: Text(pendingPracticesSectionTitle)) {
      ForEach(viewModel.pendingPracticesRows, id: \.practice.id) { practiceRow in
        NavigationLink(
          destination: {
            PracticeView(
              vocabulary: viewModel.vocabulary,
              entries: viewModel.entries,
              practice: practiceRow.practice
            )
          },
          label: {
            PendingPracticeRowView(
              title: practiceRow.practice.createdAt.formatted(),
              lastStoppedPosition: (practiceRow.practice.lastStoppedPosition ?? 0) + 1,
              totalEntries: practiceRow.entriesCount
            )
          }
        )
      }
      .onDelete { indexSet in
        indexSet.forEach { index in
          viewModel.deletePractice(viewModel.pendingPracticesRows[index])
        }
      }
    }
  }
  
  private var vocabularySectionView: some View {
    Section(header: Text(Strings.localized("Vocabulary"))) {
      ForEach(viewModel.entries, id: \.id) { entry in
        EntryRowView(
          entry: entry,
          onRemoveFromHighlights: {
            viewModel.removeFromHighlightsTapped(for: entry)
          },
          onAddToHighlights: {
            viewModel.addToHighlightsTapped(for: entry)
          }
        )
        .font(AppTypography.body)
      }
    }
  }
  
  var pendingPracticesSectionTitle: LocalizedStringResource {
    viewModel.pendingPracticesRows.count == 1
    ? Strings.localized("Pending practice")
    : Strings.localized("Pending practices")
  }
}

enum SortOption {
  case defaultSort
  case highlights
  case alphabetical
  
  var title: LocalizedStringResource {
    switch self {
    case .defaultSort:
      return Strings.localized("Default")
    case .highlights:
      return Strings.localized("Highlights")
    case .alphabetical:
      return Strings.localized("Alphabetical")
    }
  }
  
  var icon: String {
    switch self {
    case .defaultSort:
      return "list.bullet"
    case .highlights:
      return "bookmark"
    case .alphabetical:
      return "textformat"
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
    VocabularyView(vocabulary: vocab)
  }
}

