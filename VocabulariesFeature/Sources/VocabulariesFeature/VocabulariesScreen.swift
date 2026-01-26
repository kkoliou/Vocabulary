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
  
  @State var viewModel = ContentViewModel()
  
  public init() {}
  
  public var body: some View {
    List {
      ForEach(viewModel.vocabularies, id: \.id) { vocabulary in
        VStack(alignment: .leading) {
          Text(vocabulary.name)
          Text(vocabulary.createdAt.formatted())
        }
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
    VocabulariesScreen()
  }
}

@Observable @MainActor
class ContentViewModel {
  @ObservationIgnored @FetchAll var vocabularies: [Vocabulary]
}
