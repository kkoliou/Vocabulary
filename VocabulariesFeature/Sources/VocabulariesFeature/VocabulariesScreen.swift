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

public struct VocabulariesScreen: View {
  
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
      .navigationTitle("Vocabularies")
      .navigationDestination(for: Vocabulary.self) { vocabulary in
        Text(vocabulary.name)
      }
      .toolbar {
        if !isEmptyState {
          ToolbarItem(placement: .primaryAction) {
            Button(
              action: {
                
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
  }
  
  private var emptyState: some View {
    ContentUnavailableView(
      label: {
        Label("No vocabulary yet", systemImage: "book.pages.fill")
      },
      description: {
        Text("Create your first word list to start studying.")
      },
      actions: {
        Button("Add vocabulary") {
          viewModel.addVocabularyTapped()
        }
      }
    )
  }
  
  private var vocabList: some View {
    List(viewModel.vocabularies, id: \.id) { vocabulary in
      NavigationLink(value: vocabulary) {
        VStack(alignment: .leading) {
          Text(vocabulary.name)
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
    VocabulariesScreen()
  }
}

@Observable @MainActor
public class VocabulariesViewModel {
  @ObservationIgnored @FetchAll(Vocabulary.none) var vocabularies
  
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
    
  }
}
