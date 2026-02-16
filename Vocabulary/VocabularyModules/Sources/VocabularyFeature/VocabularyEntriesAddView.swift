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
          Utilities.triggerLightHaptic()
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
        .font(AppTypography.headline)
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
        .font(AppTypography.headline)
    } footer: {
      if !viewModel.hasSelectedFile {
        Text(Strings.localized("Select a CSV file from your device"))
          .font(AppTypography.footnote)
      } else if let errorMessage = viewModel.errorMessage {
        Text(errorMessage)
          .font(AppTypography.footnote)
          .foregroundColor(.red)
      }
    }
  }
  
  private var howItWorksContent: some View {
    VStack(alignment: .leading, spacing: 24) {
      VStack(alignment: .leading, spacing: 12) {
        Label(Strings.localized("CSV Format"), systemImage: "doc.text")
          .font(AppTypography.headline)
        
        Text(Strings.localized("Your CSV file should have two columns:"))
          .font(AppTypography.subheadline)
          .foregroundColor(.secondary)
        
        csvColumnsDescription
        
        Text(Strings.localized("Tip: You can use your AI agent to help generate a properly formatted CSV file."))
          .font(AppTypography.subheadline)
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
        .font(AppTypography.subheadline)
    }
  }
  
  private func selectedFileRow(fileName: String) -> some View {
    HStack {
      Image(systemName: "doc.fill")
        .foregroundColor(.accentColor)
      
      Text(fileName)
        .font(AppTypography.body)
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
          .font(AppTypography.body)
        Spacer()
        Image(systemName: "chevron.right")
          .font(AppTypography.caption)
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
