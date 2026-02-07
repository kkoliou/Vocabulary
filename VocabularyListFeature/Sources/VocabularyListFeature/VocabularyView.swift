//
//  VocabularyView.swift
//  VocabularyListFeature
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
      ForEach(viewModel.words, id: \.id) {
        Text($0.sourceWord)
      }
    }
    .navigationTitle(viewModel.vocabulary.name)
  }
}

//#Preview {
//  VocabularyView(vocabulary: Vocabulary()
//}

@Observable @MainActor
public class VocabularyViewModel {
  
  @ObservationIgnored @Dependency(\.defaultDatabase) var database
  @ObservationIgnored @FetchAll(VocabularyEntry.none) var words
  var addVocabIsPresented = false
  let vocabulary: Vocabulary
  
  public init(vocabulary: Vocabulary) {
    self.vocabulary = vocabulary
  }
  
  func doInit() async {
    _ = await withErrorReporting {
      try await $words
        .load(
          VocabularyEntry
            .where { $0.vocabularyID.eq(vocabulary.id) }
        )
    }
  }
  
}
