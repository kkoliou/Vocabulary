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
          .disabled(vocabularyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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

@Observable @MainActor
class VocabularyCreatorViewModel {
  
  @ObservationIgnored @Dependency(\.defaultDatabase) var database
  @ObservationIgnored var alertTitle: LocalizedStringResource?
  var alertIsPresented = false
  
  func addVocabularyTapped(vocabName: String) throws {
    let trimmed = vocabName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { throw AddVocabularyError.emptyName }
    try database.write { db in
      let exists = try Vocabulary
        .where { $0.name == trimmed }
        .fetchCount(db) > 0
      
      if exists {
        throw AddVocabularyError.alreadyExists
      }
      
      try Vocabulary.insert {
        Vocabulary.Draft(name: trimmed, createdAt: Date())
      }
      .execute(db)
    }
  }
  
  func handleError(_ error: Error) {
    guard let error = error as? AddVocabularyError else {
      displayAlert("Something went wrong")
      return
    }
    switch error {
    case .emptyName:
      displayAlert("Provide a vocabulary name")
    case .alreadyExists:
      displayAlert("The vocabulary already exists")
    }
  }
  
  private func displayAlert(_ message: StaticString) {
    alertTitle = Strings.localized(message)
    alertIsPresented = true
  }
}

enum AddVocabularyError: Error {
  case emptyName
  case alreadyExists
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
