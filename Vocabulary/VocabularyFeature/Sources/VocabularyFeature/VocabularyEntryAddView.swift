//
//  VocabularyEntryAddView.swift
//  VocabularyFeature
//
//  Created by Konstantinos Kolioulis on 7/2/26.
//

import SwiftUI
import SQLiteData
import VocabularyDB
import Shared

struct VocabularyEntryAddView: View {
  
  @Environment(\.dismiss) private var dismiss
  @State var viewModel: VocabularyEntriesAddViewModel
  @FocusState private var focusedField: Field?
  
  enum Field {
    case source, translation
  }
  
  public init(vocabulary: Vocabulary) {
    _viewModel = State(
      wrappedValue: VocabularyEntriesAddViewModel(
        vocabulary: vocabulary
      )
    )
  }
  
  var body: some View {
    NavigationStack {
      Form {
        Section(Strings.localized("Original")) {
          VTextField(
            text: $viewModel.source,
            promptKey: "Word or phrase"
          )
          .focused($focusedField, equals: .source)
          .autocorrectionDisabled()
          .submitLabel(.next)
          .onSubmit {
            focusedField = .translation
          }
        }
        
        Section(Strings.localized("Translation")) {
          VTextField(
            text: $viewModel.translation,
            promptKey: "Your translation"
          )
          .focused($focusedField, equals: .translation)
          .autocorrectionDisabled()
          .submitLabel(.done)
          .onSubmit {
            viewModel.saveButtonTapped()
          }
        }
      }
      .navigationTitle(Strings.localized("Add Entry"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(Strings.localized("Cancel")) {
            viewModel.cancelButtonTapped()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button(Strings.localized("Save")) {
            viewModel.saveButtonTapped()
          }
          .disabled(viewModel.saveButtonDisabled)
        }
      }
      .alert(viewModel.alertTitle ?? Strings.localized("Error"), isPresented: $viewModel.isAlertPresented) {
        Button(Strings.localized("OK"), role: .cancel) {}
      }
      .onAppear {
        focusedField = .source
      }
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
    VocabularyEntryAddView(vocabulary: vocab)
  }
}

@Observable @MainActor
class VocabularyEntriesAddViewModel {
  
  @ObservationIgnored @Dependency(\.defaultDatabase) var database
  let vocabulary: Vocabulary
  var source: String = "" {
    didSet {
      checkSaveButtonState()
    }
  }
  var translation: String = "" {
    didSet {
      checkSaveButtonState()
    }
  }
  var saveButtonDisabled: Bool = true
  var dismiss = false
  var triggerSuccess = false
  var alertTitle: LocalizedStringResource?
  var isAlertPresented = false
  
  init(vocabulary: Vocabulary) {
    self.vocabulary = vocabulary
  }
  
  private func checkSaveButtonState() {
    let sourceIsEmpty = source.trimmed().isEmpty
    let translationIsEmpty = translation.trimmed().isEmpty
    saveButtonDisabled = sourceIsEmpty || translationIsEmpty
  }
  
  func saveButtonTapped() {
    let sourceIsEmpty = source.trimmed().isEmpty
    let translationIsEmpty = translation.trimmed().isEmpty
    if sourceIsEmpty || translationIsEmpty {
      handleError(AddVocabularyEntryError.emptyName)
      return
    }
    do {
      try database.write { db in
        let exists = try VocabularyEntry
          .where { $0.sourceWord == source && $0.vocabularyID == vocabulary.id }
          .fetchCount(db) > 0

        if exists {
          throw AddVocabularyEntryError.alreadyExists
        }

        try VocabularyEntry.insert {
          VocabularyEntry.Draft(
            vocabularyID: vocabulary.id,
            sourceWord: source,
            translatedWord: translation
          )
        }
        .execute(db)
      }
      triggerSuccess = true
      dismiss = true
    } catch {
      handleError(error)
    }
  }
  
  func cancelButtonTapped() {
    dismiss = true
  }
  
  func handleError(_ error: Error) {
    guard let error = error as? AddVocabularyEntryError else {
      displayAlert("Something went wrong")
      return
    }
    switch error {
    case .emptyName:
      displayAlert("Provide both original and translation")
    case .alreadyExists:
      displayAlert("An entry with this original word already exists in this vocabulary")
    }
  }
  
  private func displayAlert(_ message: StaticString) {
    alertTitle = Strings.localized(message)
    isAlertPresented = true
  }
}

enum AddVocabularyEntryError: Error {
  case emptyName
  case alreadyExists
}
