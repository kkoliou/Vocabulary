//
//  VocabularyCreatorView.swift
//  VocabulariesFeature
//
//  Created by Konstantinos Kolioulis on 27/1/26.
//

import SwiftUI
import Foundation
import SQLiteData
import VocabularyDB
import Shared

struct VocabularyCreatorView: View {
  
  @State var viewModel: VocabularyCreatorViewModel
  @Environment(\.dismiss) private var dismiss
  @State private var vocabularyName: String = ""
  @FocusState private var isTextFieldFocused: Bool
  
  public init(
    viewModel: VocabularyCreatorViewModel = VocabularyCreatorViewModel()
  ) {
    _viewModel = State(wrappedValue: VocabularyCreatorViewModel())
  }
  
  var body: some View {
    NavigationStack {
      Form {
        Section {
          VTextField(
            text: $vocabularyName,
            promptKey: "Name"
          )
          .focused($isTextFieldFocused)
          .autocorrectionDisabled()
        } header: {
          Text(Strings.localized("Vocabulary name"))
            .font(AppTypography.headline)
        } footer: {
          Text(Strings.localized("Choose a descriptive name to organize your learning."))
            .font(AppTypography.subheadline)
        }
      }
      .navigationTitle(Strings.localized("New Vocabulary"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(
            action: {
              viewModel.addVocabularyTapped(vocabName: vocabularyName)
            },
            label: {
              Image(systemName: "checkmark")
            }
          )
          .disabled(vocabularyName.trimmed().isEmpty)
        }
      }
      .onAppear {
        isTextFieldFocused = true
      }
      .alert(
        viewModel.alertTitle ?? "",
        isPresented: $viewModel.alertIsPresented,
        actions: {}
      )
      .onChange(of: viewModel.triggerSuccess) { _, newValue in
        if newValue {
          Utilities.triggerLightHaptic()
        }
      }
      .onChange(of: viewModel.dismiss) { _, newValue in
        if newValue {
          dismiss()
        }
      }
    }
  }
}

#Preview {
  let _ = prepareDependencies {
    try! $0.bootstrapDatabase()
    try! $0.defaultDatabase.seedForPreview()
  }
  NavigationStack {
    VocabularyCreatorView()
  }
}
