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
    .navigationTitle(viewModel.vocabulary.name)
    .toolbar {
      ToolbarItemGroup(placement: .primaryAction) {
        Button("", systemImage: "plus") {
          viewModel.plusButtonTapped()
        }
      }
    }
    .task {
      await viewModel.doInit()
    }
    .vSheet(isPresented: $viewModel.isAddEntryPresented) {
      VocabularyEntryAddView(vocabulary: viewModel.vocabulary)
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
