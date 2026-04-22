//
//  VocabulariesViewModel.swift
//  VocabulariesFeature
//
//  Created by Konstantinos Kolioulis on 7/2/26.
//

import SwiftUI
import Foundation
import SQLiteData
import VocabularyDB
import Shared
import Sharing
import VocabularyCsvParser

@Observable @MainActor
public class VocabulariesViewModel {
  
  @ObservationIgnored @Dependency(\.defaultDatabase) var database
  @ObservationIgnored @FetchAll(Vocabulary.none) var vocabularies
  @ObservationIgnored var firstInitExecuted = false
  @ObservationIgnored @Shared var practiceDisplayMode: PracticeDisplayMode
  var addVocabIsPresented = false
  var settingsIsPresented = false
  var isLoading = false
  var isAddSampleVocabsLoading = false
  
  public init() {
    _practiceDisplayMode = Shared(
      wrappedValue: .cards,
      .appStorage(PracticeDisplayMode.appStorageKey)
    )
  }
  
  func doInit() async {
    setLoadingIfNeeded(true)
    _ = await withErrorReporting {
      try await $vocabularies
        .load(
          Vocabulary
            .order(by: \.createdAt),
          animation: .default
        )
    }
    setLoadingIfNeeded(false)
    firstInitExecuted = true
  }
  
  private func setLoadingIfNeeded(_ loading: Bool) {
    if firstInitExecuted { return }
    isLoading = loading
  }
  
  func addVocabularyTapped() {
    addVocabIsPresented = true
  }
  
  func changePracticeDisplayMode(to mode: PracticeDisplayMode) {
    $practiceDisplayMode.withLock { $0 = mode }
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
  
  func addPreMadeVocabularies() async {
    isAddSampleVocabsLoading = true

    @Sendable func resolveCSVFiles() throws -> [URL] {
      let bundle = Bundle.module
      
      if let urls = bundle.urls(forResourcesWithExtension: "csv", subdirectory: nil), !urls.isEmpty {
        return urls.sorted { $0.lastPathComponent < $1.lastPathComponent }
      }
      
      throw NSError(
        domain: "Bundle",
        code: -1,
        userInfo: [NSLocalizedDescriptionKey: "Could not find any CSV files in bundle."]
      )
    }

    await withErrorReporting {
      try await database.write { db in
        let csvFiles = try resolveCSVFiles()

        for csvURL in csvFiles {
          let words = try VocabularyCsvParser.parse(fileUrl: csvURL)
          let vocabName = csvURL.deletingPathExtension().lastPathComponent
          let vocabId = UUID()
          try Vocabulary.insert {
            Vocabulary.Draft(id: vocabId, name: vocabName, createdAt: Date())
          }
          .execute(db)
          
          try db.seed {
            for word in words {
              VocabularyEntry.Draft(
                vocabularyID: vocabId,
                sourceWord: word.source,
                translatedWord: word.translated,
                isHighlighted: false
              )
            }
          }
        }
      }
    }
    
    isAddSampleVocabsLoading = false
  }
  
  func settingsTapped() {
    settingsIsPresented = true
  }
}
