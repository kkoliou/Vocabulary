//
//  ContentView.swift
//  Vocabulary
//
//  Created by Konstantinos Kolioulis on 20/1/26.
//

import SwiftUI
import SQLiteData
import VocabularyDB

struct ContentView: View {
  
  @State var viewModel = ContentViewModel()
  
  var body: some View {
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
  ContentView()
}

@Observable @MainActor
class ContentViewModel {
  @ObservationIgnored @FetchAll var vocabularies: [Vocabulary]
}
