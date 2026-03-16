//
//  VocabulariesScreen.swift
//  VocabulariesFeature
//
//  Created by Konstantinos Kolioulis on 26/1/26.
//

import SwiftUI
import Foundation
import SQLiteData
import VocabularyDB
import Shared
import VocabularyFeature

public struct VocabulariesView: View {
  
  @State var viewModel: VocabulariesViewModel
  
  public init(viewModel: VocabulariesViewModel = VocabulariesViewModel()) {
    _viewModel = State(wrappedValue: VocabulariesViewModel())
  }
  
  public var body: some View {
    NavigationStack {
      Group {
        if viewModel.isLoading {
          ProgressView()
        } else if viewModel.vocabularies.isEmpty {
          emptyState
        } else {
          vocabList
        }
      }
      .navigationTitle(Strings.localized("Vocabularies"))
      .navigationDestination(for: Vocabulary.self) {
        VocabularyView(vocabulary: $0)
      }
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button(
            action: {
              viewModel.addVocabularyTapped()
            },
            label: {
              Image(systemName: "plus")
            }
          )
        }
      }
    }
    .task {
      await viewModel.doInit()
    }
    .vSheet(isPresented: $viewModel.addVocabIsPresented) {
      VocabularyCreatorView()
        .largePresentationDetents()
    }
  }
  
  private var emptyState: some View {
    VStack(spacing: 24) {
      ContentUnavailableView(
        label: {
          Label(Strings.localized("No vocabulary yet"), systemImage: "book.pages.fill")
            .font(AppTypography.title3)
        },
        description: {
          Text(Strings.localized("Add English-Greek vocabularies to get started"))
            .font(AppTypography.subheadline)
        },
        actions: {
          Button(
            action: {
              Task {
                await viewModel.addPreMadeVocabularies()
              }
            },
            label: {
              HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                  .font(AppTypography.callout)
                
                Text(Strings.localized("Add vocabularies"))
                  .font(AppTypography.callout.weight(.semibold))
              }
              .opacity(viewModel.isAddSampleVocabsLoading ? 0 : 1)
              .overlay {
                if viewModel.isAddSampleVocabsLoading {
                  ProgressView()
                }
              }
              .animation(.easeInOut(duration: 0.25), value: viewModel.isAddSampleVocabsLoading)
              .padding(.horizontal, 12)
              .padding(.vertical, 12)
              .clipShape(.capsule)
              .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
            }
          )
          .buttonStyle(.bordered)
          .disabled(viewModel.isAddSampleVocabsLoading)
        }
      )
    }
  }
  
  private var vocabList: some View {
    List {
      ForEach(viewModel.vocabularies, id: \.id) { vocabulary in
        NavigationLink(value: vocabulary) {
          VStack(alignment: .leading) {
            Text(vocabulary.name)
              .font(AppTypography.body)
          }
        }
      }
      .onDelete { indexSet in
        Task {
          await viewModel.deleteVocabularies(at: indexSet)
        }
      }
    }
  }
}

#Preview {
  let _ = prepareDependencies {
    try! $0.bootstrapDatabase()
  }
  NavigationStack {
    VocabulariesView()
  }
}
