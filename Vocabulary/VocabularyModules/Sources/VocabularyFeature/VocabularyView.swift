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
    Group {
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
          Button("Add Entry", systemImage: "plus") {
            viewModel.addEntryTapped()
          }
          Button("Import File", systemImage: "tray.and.arrow.down") {
            viewModel.addFileTapped()
          }
        } label: {
          Label("Add", systemImage: "plus")
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
