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
      .navigationDestination(for: Vocabulary.self) { vocabulary in
        Text(vocabulary.name)
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
        .presentationDetents([.medium])
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

@Observable @MainActor
public class VocabulariesViewModel {
  
  @ObservationIgnored @Dependency(\.defaultDatabase) var database
  @ObservationIgnored @FetchAll(Vocabulary.none) var vocabularies
  var addVocabIsPresented = false
  
  public init() {}
  
  func doInit() async {
    await withErrorReporting {
      try await $vocabularies
        .load(
          Vocabulary
            .order(by: \.createdAt)
        )
    }
  }
  
  func addVocabularyTapped() {
    addVocabIsPresented = true
  }
  
  func deleteVocabularies(at offsets: IndexSet) async {
    withErrorReporting {
      try database.write { db in
        try Vocabulary.find(offsets.map { vocabularies[$0].id })
          .delete()
          .execute(db)
      }
    }
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
