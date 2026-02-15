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

public struct VocabularyView: View {
  
  @State var viewModel: VocabularyViewModel
  
  public init(vocabulary: Vocabulary) {
    _viewModel = State(wrappedValue: VocabularyViewModel(vocabulary: vocabulary))
  }
  
  public var body: some View {
    Form {
      if viewModel.$entries.isLoading {
        ProgressView()
      } else {
        List {
          ForEach(viewModel.entries, id: \.id) { entry in
            EntryRow(
              entry: entry,
              onRemoveFromHighlights: {
                viewModel.removeFromHighlightsTapped(for: entry)
              },
              onAddToHighlights: {
                viewModel.addToHighlightsTapped(for: entry)
              }
            )
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
