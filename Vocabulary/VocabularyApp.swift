import SwiftUI
import SQLiteData

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
