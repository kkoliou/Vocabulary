//
//  VocabularyApp.swift
//  Vocabulary
//
//  Created by Konstantinos Kolioulis on 20/1/26.
//

import SwiftUI
import SQLiteData
import VocabularyDB

@main
struct VocabularyApp: App {
  
  init() {
    prepareDependencies {
      try! $0.bootstrapDatabase()
      try! $0.defaultDatabase.seed()
    }
  }
  
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
