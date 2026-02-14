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
      .navigationTitle("Import from File")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        importToolbarItem
      }
      .fileImporter(
        isPresented: $viewModel.isPickerPresented,
        allowedContentTypes: [.commaSeparatedText, .plainText],
        allowsMultipleSelection: false,
        onCompletion: viewModel.handleFileSelection
      )
    }
  }
  
  private var howItWorksSection: some View {
    Section {
      howItWorksContent
        .padding(.vertical, 4)
    } header: {
      Text("How It Works")
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
      Text("File")
    } footer: {
      if !viewModel.hasSelectedFile {
        Text("Select a CSV file from your device")
      }
    }
  }
  
  private var howItWorksContent: some View {
    VStack(alignment: .leading, spacing: 24) {
      VStack(alignment: .leading, spacing: 12) {
        Label("CSV Format", systemImage: "doc.text")
          .font(.headline)
        
        Text("Your CSV file should have two columns:")
          .font(.subheadline)
          .foregroundColor(.secondary)
        
        csvColumnsDescription
        
        Text("Tip: You can use your AI agent to help generate a properly formatted CSV file for import, with the languages you want.")
          .font(.subheadline)
          .foregroundColor(.accentColor)
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
  
  private func csvBullet(_ text: String) -> some View {
    HStack(spacing: 12) {
      Circle()
        .fill(Color.blue)
        .frame(width: 8, height: 8)
      Text(text)
        .font(.subheadline)
    }
  }
  
  private func selectedFileRow(fileName: String) -> some View {
    HStack {
      Image(systemName: "doc.fill")
        .foregroundColor(.blue)
      
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
        Text("Choose CSV File")
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
          importFile()
        },
        label: {
          Image(systemName: "checkmark")
        }
      )
      .disabled(!viewModel.hasSelectedFile)
    }
  }
  
  private func importFile() {
    guard viewModel.hasSelectedFile else { return }
    
    UIImpactFeedbackGenerator(style: .light)
      .impactOccurred()
    
    viewModel.importEntries()
    dismiss()
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
  let vocabulary: Vocabulary
  var isPickerPresented = false
  var selectedFileURL: URL?
  var fileName: String?
  
  init(vocabulary: Vocabulary) {
    self.vocabulary = vocabulary
  }
  
  var hasSelectedFile: Bool {
    selectedFileURL != nil
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
  
  func setFile(url: URL, fileName: String) {
    self.selectedFileURL = url
    self.fileName = fileName
  }
  
  func clearFile() {
    selectedFileURL = nil
    fileName = nil
  }
  
  func importEntries() {
    guard let url = selectedFileURL else { return }
    // TODO
  }
}
