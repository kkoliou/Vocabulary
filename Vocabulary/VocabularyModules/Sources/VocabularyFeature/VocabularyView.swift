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
    Group {
      if viewModel.isLoading {
        HStack() {
          Spacer()
          ProgressView()
          Spacer()
        }
      } else if !viewModel.pendingPracticesRows.isEmpty || !viewModel.entries.isEmpty {
        List {
          if !viewModel.pendingPracticesRows.isEmpty {
            practicesSectionView
          }
          if !viewModel.entries.isEmpty {
            vocabularySectionView
          }
        }
        .searchable(text: $viewModel.searchText, prompt: Strings.localized("Search in vocabulary"))
      } else {
        ContentUnavailableView(
          Strings.localized("No entries"),
          systemImage: "book.closed"
        )
      }
    }
    .navigationTitle(viewModel.vocabulary.name)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItemGroup(placement: .primaryAction) {
        sortingActionView
        entriesActionView
        practiceActionView
      }
    }
    .task {
      await viewModel.doInit()
    }
    .vSheet(isPresented: $viewModel.isAddEntryPresented) {
      VocabularyEntryAddView(vocabulary: viewModel.vocabulary)
        .largePresentationDetents()
    }
    .vSheet(isPresented: $viewModel.isEditEntryPresented) {
      if let entryToEdit = viewModel.entryToEdit {
        VocabularyEntryAddView(vocabulary: viewModel.vocabulary, entryToEdit: entryToEdit)
          .largePresentationDetents()
      }
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
          practice: nil,
          scope: viewModel.selectedPracticeScope
        )
      }
    )
    .alert(
      Strings.localized("Create new practice?"),
      isPresented: $viewModel.isCreatePracticeAlertPresented
    ) {
      Button(Strings.localized("Cancel"), role: .cancel) {}
      Button(Strings.localized("Create")) {
        viewModel.confirmCreateNewPractice()
      }
    } message: {
      Text(Strings.localized("You already have a pending practice. Creating a new one will replace it. Are you sure you want to continue?"))
    }
  }
  
  private var practicesSectionView: some View {
    Section(header: Text(pendingPracticesSectionTitle)) {
      ForEach(viewModel.pendingPracticesRows, id: \.practice.id) { practiceRow in
        NavigationLink(
          destination: {
            PracticeView(
              vocabulary: viewModel.vocabulary,
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
        viewModel.deletePractices(at: indexSet)
      }
    }
  }
  
  private var vocabularySectionView: some View {
    Section(header: Text(Strings.localized("Vocabulary"))) {
      ForEach(viewModel.filteredEntries, id: \.id) { entry in
        EntryRowView(
          entry: entry,
          onRemoveFromHighlights: {
            Task {
              await sleepAfterHighlightingIfNeeded()
              await viewModel.removeFromHighlightsTapped(for: entry)
            }
          },
          onAddToHighlights: {
            Task {
              await sleepAfterHighlightingIfNeeded()
              await viewModel.addToHighlightsTapped(for: entry)
            }
          },
          onEdit: {
            viewModel.editEntry(entry)
          },
          onDelete: {
            viewModel.deleteEntry(entry)
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
  
  @ViewBuilder
  private var sortingActionView: some View {
    Menu {
      Picker(Strings.localized("Sort By"), selection: $viewModel.sortOption) {
        ForEach([SortOption.defaultSort, .highlights, .alphabetical], id: \.self) { option in
          Label(option.title, systemImage: option.icon)
            .font(AppTypography.body)
            .tag(option)
        }
      }
      .pickerStyle(.inline)
      .onChange(of: viewModel.sortOption) { _, newValue in
        Task {
          await viewModel.changeSortOption(to: newValue)
        }
      }
    } label: {
      Label(Strings.localized("Sort"), systemImage: "arrow.up.arrow.down")
    }
  }
  
  @ViewBuilder
  private var entriesActionView: some View {
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
  }
  
  @ViewBuilder
  private var practiceActionView: some View {
    if !viewModel.highlightedEntries.isEmpty {
      Menu {
        Button(Strings.localized("Highlights"), systemImage: "bookmark") {
          viewModel.startPractice(scope: .highlights)
        }
        Button(Strings.localized("All vocabulary"), systemImage: "book.pages") {
          viewModel.startPractice(scope: .all)
        }
      } label: {
        Label(Strings.localized("Practice"), systemImage: "brain.head.profile")
      }
    } else {
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
  
  /// Let the cell's swipe animation finish and then execute the rest
  private func sleepAfterHighlightingIfNeeded() async {
    guard viewModel.sortOption == .highlights else { return }
    try? await Task.sleep(for: .seconds(0.8))
  }
}

enum SortOption: String, Equatable {
  case defaultSort = "default"
  case highlights = "highlights"
  case alphabetical = "alphabetical"
  
  var title: LocalizedStringResource {
    switch self {
    case .defaultSort:
      return Strings.localized("Default")
    case .highlights:
      return Strings.localized("Highlight")
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
