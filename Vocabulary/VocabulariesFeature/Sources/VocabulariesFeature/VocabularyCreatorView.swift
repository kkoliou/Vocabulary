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
          TextField(
            text: $vocabularyName,
            prompt: Text(Strings.localized("Name")),
            label: {
              EmptyView()
            }
          )
          .focused($isTextFieldFocused)
          .autocorrectionDisabled()
        } header: {
          Text(Strings.localized("Vocabulary name"))
        } footer: {
          Text(Strings.localized("Choose a descriptive name to organize your learning."))
        }
      }
      .navigationTitle(Strings.localized("New Vocabulary"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(Strings.localized("Cancel")) {
            dismiss()
          }
        }
        
        ToolbarItem(placement: .confirmationAction) {
          Button(Strings.localized("Add")) {
            createVocabulary()
          }
          .disabled(vocabularyName.trimmed().isEmpty)
          .fontWeight(.semibold)
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
    }
  }
  
  private func createVocabulary() {
    do {
      try viewModel.addVocabularyTapped(vocabName: vocabularyName)
    } catch let error {
      viewModel.handleError(error)
      return
    }
    
    let generator = UIImpactFeedbackGenerator(style: .light)
    generator.impactOccurred()
    
    dismiss()
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
