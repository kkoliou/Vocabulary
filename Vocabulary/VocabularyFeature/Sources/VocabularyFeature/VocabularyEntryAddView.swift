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
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button(Strings.localized("Save")) {
            viewModel.saveButtonTapped()
          }
          .disabled(viewModel.saveButtonDisabled)
        }
      }
      .onAppear {
        focusedField = .source
      }
    }
  }
}

//#Preview {
//  VocabularyEntryAddView(vocabulary: ))
//}

@Observable @MainActor
class VocabularyEntriesAddViewModel {
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
  
  init(vocabulary: Vocabulary) {
    self.vocabulary = vocabulary
  }
  
  private func checkSaveButtonState() {
    let sourceIsEmpty = source.trimmed().isEmpty
    let translationIsEmpty = translation.trimmed().isEmpty
    saveButtonDisabled = sourceIsEmpty || translationIsEmpty
  }
  
  func saveButtonTapped() {
    //    let english = englishText.trimmed()
    //    let greek = greekText.trimmed()
    //
    //    guard !english.isEmpty && !greek.isEmpty else {
    //      return
    //    }
    //
    //    dismiss()
  }
}
