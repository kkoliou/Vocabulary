//
//  VocabularyEntriesAddView.swift
//  VocabularyFeature
//
//  Created by Konstantinos Kolioulis on 8/2/26.
//

import SwiftUI
import UniformTypeIdentifiers
import VocabularyDB
import SQLiteData
import VocabularyCsvParser
import Shared

struct VocabularyEntriesAddView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var viewModel: VocabularyEntriesAddViewModel
  
  init(vocabulary: Vocabulary) {
    _viewModel = State(
      wrappedValue: VocabularyEntriesAddViewModel(
        vocabulary: vocabulary
      )
    )
  }
  
  var body: some View {
    NavigationStack {
      List {
        howItWorksSection
        fileSelectionSection
      }
      .navigationTitle(Strings.localized("Import from File"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        importToolbarItem
      }
      .fileImporter(
        isPresented: $viewModel.isPickerPresented,
        allowedContentTypes: [.csv],
        allowsMultipleSelection: false,
        onCompletion: viewModel.handleFileSelection
      )
      .onChange(of: viewModel.dismiss) { _, newValue in
        if newValue {
          dismiss()
        }
      }
      .onChange(of: viewModel.triggerSuccess) { _, newValue in
        if newValue {
          let generator = UIImpactFeedbackGenerator(style: .light)
          generator.impactOccurred()
        }
      }
    }
  }
  
  private var howItWorksSection: some View {
    Section {
      howItWorksContent
        .padding(.vertical, 4)
    } header: {
      Text(Strings.localized("How It Works"))
    }
  }
  
  private var fileSelectionSection: some View {
    Section {
      if let fileName = viewModel.fileName {
        selectedFileRow(fileName: fileName)
      } else {
        chooseFileButton
      }
    } header: {
      Text(Strings.localized("File"))
    } footer: {
      if !viewModel.hasSelectedFile {
        Text(Strings.localized("Select a CSV file from your device"))
      } else if let errorMessage = viewModel.errorMessage {
        Text(errorMessage)
          .font(.footnote)
          .foregroundColor(.red)
      }
    }
  }
  
  private var howItWorksContent: some View {
    VStack(alignment: .leading, spacing: 24) {
      VStack(alignment: .leading, spacing: 12) {
        Label(Strings.localized("CSV Format"), systemImage: "doc.text")
          .font(.headline)
        
        Text(Strings.localized("Your CSV file should have two columns:"))
          .font(.subheadline)
          .foregroundColor(.secondary)
        
        csvColumnsDescription
        
        Text(Strings.localized("Tip: You can use your AI agent to help generate a properly formatted CSV file."))
          .font(.subheadline)
          .foregroundColor(.secondary)
          .padding(.top, 4)
      }
    }
  }
  
  private var csvColumnsDescription: some View {
    VStack(alignment: .leading, spacing: 8) {
      csvBullet("First column: Original word or phrase")
      csvBullet("Second column: Translation")
    }
    .padding(.leading, 4)
  }
  
  private func csvBullet(_ textKey: StaticString) -> some View {
    HStack(spacing: 12) {
      Circle()
        .frame(width: 8, height: 8)
      Text(Strings.localized(textKey))
        .font(.subheadline)
    }
  }
  
  private func selectedFileRow(fileName: String) -> some View {
    HStack {
      Image(systemName: "doc.fill")
        .foregroundColor(.accentColor)
      
      Text(fileName)
        .lineLimit(1)
      
      Spacer()
      
      Button {
        viewModel.clearFile()
      } label: {
        Image(systemName: "xmark.circle.fill")
          .foregroundColor(.secondary)
      }
      .buttonStyle(.plain)
    }
  }
  
  private var chooseFileButton: some View {
    Button {
      viewModel.selectFile()
    } label: {
      HStack {
        Image(systemName: "doc.badge.plus")
        Text(Strings.localized("Choose CSV File"))
        Spacer()
        Image(systemName: "chevron.right")
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
  }
  
  private var importToolbarItem: some ToolbarContent {
    ToolbarItem(placement: .confirmationAction) {
      Button(
        action: {
          Task { @MainActor in
            await importFile()
          }
        },
        label: {
          if viewModel.isImporting {
            ProgressView()
          } else {
            Image(systemName: "checkmark")
          }
        }
      )
      .disabled(!viewModel.hasSelectedFile)
    }
  }
  
  private func importFile() async {
    guard viewModel.hasSelectedFile else { return }
    
    UIImpactFeedbackGenerator(style: .light)
      .impactOccurred()
    
    await viewModel.importEntries()
  }
}

extension UTType {
  static var csv: UTType {
    UTType(filenameExtension: "csv") ?? .commaSeparatedText
  }
}

#Preview {
  let vocab = prepareDependencies {
    try! $0.bootstrapDatabase()
    try! $0.defaultDatabase.seedForPreview()
    return try! $0.defaultDatabase.read { db in
      try Vocabulary.fetchOne(db)!
    }
  }
  
  NavigationStack {
    VocabularyEntriesAddView(vocabulary: vocab)
  }
}

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
      print("File selection error: \(error.localizedDescription)")
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
