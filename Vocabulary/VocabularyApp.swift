//
//  VocabularyApp.swift
//  Vocabulary
//
//  Created by Konstantinos Kolioulis on 20/1/26.
//

import SwiftUI
import SQLiteData
import VocabularyDB
import VocabulariesFeature

@main
struct VocabularyApp: App {
  
  init() {
    prepareDependencies {
      try! $0.bootstrapDatabase()
    }
  }
  
  var body: some Scene {
    WindowGroup {
      VocabulariesView()
    }
  }
}
