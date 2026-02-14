//
//  VocabularyEntriesAddViewModel.swift
//  VocabularyFeature
//
//  Created by Konstantinos Kolioulis on 14/2/26.
//

import SQLiteData
import Observation
import Shared
import VocabularyCsvParser
import VocabularyDB
import Foundation

@Observable @MainActor
class VocabularyEntriesAddViewModel {
  
  @ObservationIgnored @Dependency(\.defaultDatabase) var database
  let vocabulary: Vocabulary
  var isPickerPresented = false
  var isImporting = false
  var fileName: String?
  var fileContent: String?
  var errorMessage: LocalizedStringResource?
  var dismiss = false
  var triggerSuccess = false
  
  init(vocabulary: Vocabulary) {
    self.vocabulary = vocabulary
  }
  
  var hasSelectedFile: Bool {
    fileContent != nil
  }
  
  func selectFile() {
    isPickerPresented = true
  }
  
  func handleFileSelection(_ result: Result<[URL], Error>) {
    switch result {
    case .success(let urls):
      guard let url = urls.first else { return }
      setFile(
        url: url,
        fileName: url.lastPathComponent
      )
      
    case .failure(let error):
      reportIssue("File selection error: \(error.localizedDescription)")
    }
  }
  
  private func setFile(url: URL, fileName: String) {
    let access = url.startAccessingSecurityScopedResource()
    defer {
      if access {
        url.stopAccessingSecurityScopedResource()
      }
    }
    
    self.fileContent = try? String(contentsOf: url, encoding: .utf8)
    self.fileName = fileName
  }
  
  func clearFile() {
    errorMessage = nil
    fileContent = nil
    fileName = nil
  }
  
  func importEntries() async {
    guard let fileContent else { return }
    do {
      isImporting = true
      let entries = try await parseFileContent(fileContent)
      try await storeEntries(entries)
      triggerSuccess = true
      dismiss = true
      isImporting = false
    } catch {
      isImporting = false
      handleImportingError(error)
    }
  }
  
  private func handleImportingError(_ error: Error) {
    if let error = error as? VocabularyCsvParser.ParseError {
      switch error {
      case .fileNotFound:
        errorMessage = Strings.localized("Could not read the selected file. Please try again.")
      case .invalidFormat:
        errorMessage = Strings.localized("The file format is invalid. Please ensure your CSV uses commas to separate values.")
      case .missingRequiredFields:
        errorMessage = Strings.localized("One or more rows are missing required fields (original or translation). Please check your CSV.")
      }
    } else {
      errorMessage = Strings.localized("Something went wrong.")
    }
  }
  
  @concurrent
  private func parseFileContent(
    _ fileContent: String
  ) async throws -> [VocabularyWord] {
    return try VocabularyCsvParser.parse(csvString: fileContent)
  }
  
  @concurrent
  private func storeEntries(_ entries: [VocabularyWord]) async throws {
    try await database.write { db in
        try db.seed {
          for entry in entries {
          VocabularyEntry.Draft(
            vocabularyID: vocabulary.id,
            sourceWord: entry.source,
            translatedWord: entry.translated,
            isHighlighted: false
          )
        }
      }
    }
  }
}
