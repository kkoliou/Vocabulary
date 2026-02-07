//
//  VocabulariesScreen.swift
//  VocabulariesFeature
//
//  Created by Konstantinos Kolioulis on 26/1/26.
//

import SwiftUI
import Foundation
import SQLiteData
import VocabularyDB
import Shared
import VocabularyListFeature

public struct VocabulariesView: View {
  
  @State var viewModel: VocabulariesViewModel
  
  public init(viewModel: VocabulariesViewModel = VocabulariesViewModel()) {
    _viewModel = State(wrappedValue: VocabulariesViewModel())
  }
  
  public var body: some View {
    NavigationStack {
      Group {
        if isEmptyState {
          emptyState
        } else {
          vocabList
        }
      }
      .navigationTitle(Strings.localized("Vocabularies"))
      .navigationDestination(for: Vocabulary.self) {
        VocabularyView(vocabulary: $0)
      }
      .toolbar {
        if !isEmptyState {
          ToolbarItem(placement: .primaryAction) {
            Button(
              action: {
                viewModel.addVocabularyTapped()
              },
              label: {
                Image(systemName: "plus")
              }
            )
          }
        }
      }
    }
    .task {
      await viewModel.doInit()
    }
    .sheet(isPresented: $viewModel.addVocabIsPresented) {
      VocabularyCreatorView()
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
  }
  
  private var emptyState: some View {
    ContentUnavailableView(
      label: {
        Label(Strings.localized("No vocabulary yet"), systemImage: "book.pages.fill")
      },
      description: {
        Text(Strings.localized("Create your first word list to start studying."))
      },
      actions: {
        Button(Strings.localized("Add vocabulary")) {
          viewModel.addVocabularyTapped()
        }
      }
    )
  }
  
  private var vocabList: some View {
    List {
      ForEach(viewModel.vocabularies, id: \.id) { vocabulary in
        NavigationLink(value: vocabulary) {
          VStack(alignment: .leading) {
            Text(vocabulary.name)
          }
        }
      }
      .onDelete { indexSet in
        Task {
          await viewModel.deleteVocabularies(at: indexSet)
        }
      }
    }
  }
  
  private var isEmptyState: Bool {
    !viewModel.$vocabularies.isLoading && viewModel.vocabularies.isEmpty
  }
}

#Preview {
  let _ = prepareDependencies {
    try! $0.bootstrapDatabase()
    try! $0.defaultDatabase.seedForPreview()
  }
  NavigationStack {
    VocabulariesView()
  }
}
