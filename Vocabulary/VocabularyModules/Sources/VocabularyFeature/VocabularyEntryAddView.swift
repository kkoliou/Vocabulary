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
  @State var viewModel: VocabularyEntryAddViewModel
  @FocusState private var focusedField: Field?
  
  enum Field {
    case source, translation
  }
  
  public init(vocabulary: Vocabulary) {
    _viewModel = State(
      wrappedValue: VocabularyEntryAddViewModel(
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
        ToolbarItem(placement: .confirmationAction) {
          Button(action: { viewModel.saveButtonTapped() }) {
            Image(systemName: "checkmark")
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
