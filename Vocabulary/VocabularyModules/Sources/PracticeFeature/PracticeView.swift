//
//  PracticeView.swift
//  VocabularyModules
//
//  Created by Konstantinos Kolioulis on 15/2/26.
//

import SwiftUI
import VocabularyDB
import SQLiteData

//public struct PracticeView: View {
//
//  @State private var viewModel: PracticeViewModel
//
//  public init(vocabulary: Vocabulary) {
//    _viewModel = State(wrappedValue: PracticeViewModel(vocabulary: vocabulary))
//  }
//
//  public var body: some View {
//    Text("Hello, World!")
//  }
//}
//
//#Preview {
//  let vocab = prepareDependencies {
//    try! $0.bootstrapDatabase()
//    try! $0.defaultDatabase.seedForPreview()
//    return try! $0.defaultDatabase.read { db in
//      try Vocabulary.fetchOne(db)!
//    }
//  }
//
//  NavigationStack {
//    PracticeView(vocabulary: vocab)
//  }
//}
//
//@Observable @MainActor
//public class PracticeViewModel {
//  let vocabulary: Vocabulary
//
//  public init(vocabulary: Vocabulary) {
//    self.vocabulary = vocabulary
//  }
//}


//
//  PracticeView.swift
//  VocabularyFeature
//

import SwiftUI

//
//  PracticeView.swift
//  VocabularyFeature
//

import SwiftUI

public struct PracticeView: View {
  
  @Environment(\.dismiss) private var dismiss
  @State var viewModel: PracticeViewModel
  @State private var cardRotation: Double = 0
  
  public init(vocabulary: Vocabulary, entries: [VocabularyEntry]) {
    _viewModel = State(
      wrappedValue: PracticeViewModel(
        vocabulary: vocabulary,
        entries: entries
      )
    )
  }
  
  public var body: some View {
    //    NavigationStack {
    ZStack {
      // Background gradient
      LinearGradient(
        colors: [
          Color(.systemBackground),
          Color(.systemGray6).opacity(0.3)
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()
      
      VStack(spacing: 0) {
        // Progress Section
        VStack(spacing: 12) {
          HStack {
            Text(viewModel.progressText)
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(viewModel.vocabulary.name)
              .font(.subheadline.weight(.medium))
              .foregroundStyle(.secondary)
          }
          
          GeometryReader { geometry in
            ZStack(alignment: .leading) {
              // Background track
              RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(height: 8)
              
              // Progress fill
              RoundedRectangle(cornerRadius: 8)
                .fill(
                  LinearGradient(
                    colors: [.blue, .cyan],
                    startPoint: .leading,
                    endPoint: .trailing
                  )
                )
                .frame(width: geometry.size.width * viewModel.progress, height: 8)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.progress)
            }
          }
          .frame(height: 8)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 16)
        
        // Card Area
        if let entry = viewModel.currentEntry {
          GeometryReader { geometry in
            VStack {
              Spacer()
              
              // Card with flip animation
              ZStack {
                // Card container
                RoundedRectangle(cornerRadius: 24)
                  .fill(Color(.systemBackground))
                  .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 10)
                  .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 1)
                
                VStack(spacing: 0) {
                  Spacer()
                  
                  // Source Word
                  VStack(spacing: 16) {
                    Text(entry.sourceWord)
                      .font(.system(size: 38, weight: .bold, design: .rounded))
                      .multilineTextAlignment(.center)
                      .foregroundColor(.primary)
                      .padding(.horizontal, 32)
                      .minimumScaleFactor(0.5)
                      .lineLimit(3)
                    
                    // Language indicator
                    HStack(spacing: 6) {
                      Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 6, height: 6)
                      Text("Original")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    }
                  }
                  
                  Spacer()
                  
                  // Divider with decoration
                  HStack(spacing: 12) {
                    Rectangle()
                      .fill(Color(.systemGray4))
                      .frame(height: 1)
                    
                    Image(systemName: "arrow.down")
                      .font(.caption2)
                      .foregroundStyle(.tertiary)
                    
                    Rectangle()
                      .fill(Color(.systemGray4))
                      .frame(height: 1)
                  }
                  .padding(.horizontal, 60)
                  .padding(.vertical, 24)
                  
                  Spacer()
                  
                  // Translation Area
                  VStack(spacing: 16) {
                    if viewModel.isTranslationRevealed {
                      VStack(spacing: 12) {
                        Text(entry.translatedWord)
                          .font(.system(size: 32, weight: .semibold, design: .rounded))
                          .multilineTextAlignment(.center)
                          .foregroundStyle(.blue)
                          .padding(.horizontal, 32)
                          .minimumScaleFactor(0.5)
                          .lineLimit(3)
                          .transition(.asymmetric(
                            insertion: .scale(scale: 0.9).combined(with: .opacity),
                            removal: .scale(scale: 0.9).combined(with: .opacity)
                          ))
                        
                        HStack(spacing: 6) {
                          Circle()
                            .fill(Color.cyan.opacity(0.2))
                            .frame(width: 6, height: 6)
                          Text("Translation")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        }
                      }
                    } else {
                      Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                          viewModel.revealTranslation()
                        }
                      } label: {
                        HStack(spacing: 10) {
                          Image(systemName: "eye.fill")
                            .font(.callout)
                          Text("Reveal Translation")
                            .font(.callout.weight(.semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                          LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                          )
                        )
                        .cornerRadius(12)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                      }
                      .transition(.scale(scale: 0.9).combined(with: .opacity))
                    }
                  }
                  .frame(minHeight: 100)
                  
                  Spacer()
                }
                .padding(.vertical, 40)
              }
              .frame(height: min(geometry.size.height * 0.75, 500))
              .padding(.horizontal, 24)
              .rotation3DEffect(
                .degrees(cardRotation),
                axis: (x: 0, y: 1, z: 0)
              )
              
              Spacer()
            }
          }
        } else {
          VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "book.closed")
              .font(.system(size: 60))
              .foregroundStyle(.tertiary)
            
            Text("No Entries")
              .font(.title2.weight(.semibold))
            
            Text("Add some vocabulary entries to practice")
              .font(.subheadline)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)
            
            Spacer()
          }
          .padding(.horizontal, 40)
        }
        
        // Navigation Controls
        HStack(spacing: 20) {
          // Previous Button
          Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
              viewModel.previousEntry()
            }
          } label: {
            ZStack {
              Circle()
                .fill(viewModel.canGoPrevious ? Color(.systemGray6) : Color(.systemGray6).opacity(0.5))
                .frame(width: 56, height: 56)
              
              Image(systemName: "chevron.left")
                .font(.title3.weight(.semibold))
                .foregroundColor(viewModel.canGoPrevious ? .primary : .secondary.opacity(0.5))
            }
          }
          .disabled(!viewModel.canGoPrevious)
          
          Spacer()
          
          // Card indicator dots
          HStack(spacing: 8) {
            ForEach(0..<min(viewModel.entries.count, 5), id: \.self) { index in
              Circle()
                .fill(index == min(viewModel.currentIndex, 4) ? Color.blue : Color(.systemGray4))
                .frame(width: 8, height: 8)
                .animation(.spring(response: 0.3), value: viewModel.currentIndex)
            }
          }
          
          Spacer()
          
          // Next Button
          Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
              viewModel.nextEntry()
            }
          } label: {
            ZStack {
              Circle()
                .fill(
                  viewModel.canGoNext ?
                  LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing) :
                    LinearGradient(colors: [Color(.systemGray6).opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 56, height: 56)
                .shadow(color: viewModel.canGoNext ? .blue.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
              
              Image(systemName: "chevron.right")
                .font(.title3.weight(.semibold))
                .foregroundColor(viewModel.canGoNext ? .white : .secondary.opacity(0.5))
            }
          }
          .disabled(!viewModel.canGoNext)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
      }
    }
    .navigationTitle("Practice")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Done") {
          dismiss()
        }
        .fontWeight(.medium)
      }
    }
    .task {
      await viewModel.doInit()
    }
    //    }
  }
}

//#Preview {
//  PracticeView(vocabulary: Vocabulary(id: UUID(), name: "Greek"))
//}

//#Preview {
//  PracticeView(
//    vocabulary: Vocabulary(name: "Greek"),
//    entries: [
//      VocabularyEntry(source: "hello", translation: "γεια σου"),
//      VocabularyEntry(source: "goodbye", translation: "αντίο"),
//      VocabularyEntry(source: "thank you", translation: "ευχαριστώ"),
//      VocabularyEntry(source: "please", translation: "παρακαλώ"),
//      VocabularyEntry(source: "yes", translation: "ναι"),
//      VocabularyEntry(source: "no", translation: "όχι")
//    ]
//  )
//}

//
//  PracticeViewModel.swift
//  VocabularyFeature
//

import Foundation
import SwiftUI

@MainActor
@Observable
class PracticeViewModel {
  
  let vocabulary: Vocabulary
  let entries: [VocabularyEntry]
  var currentIndex: Int = 0
  var isTranslationRevealed: Bool = false
  
  public init(vocabulary: Vocabulary, entries: [VocabularyEntry]) {
    self.vocabulary = vocabulary
    self.entries = entries
  }
  
  func doInit() async {
//    _ = await withErrorReporting {
//      try await $entries
//        .load(
//          VocabularyEntry
//            .where { $0.vocabularyID.eq(vocabulary.id) },
//          animation: .default
//        )
//    }
  }
  
  var currentEntry: VocabularyEntry? {
    guard !entries.isEmpty, currentIndex < entries.count else { return nil }
    return entries[currentIndex]
  }
  
  var progress: Double {
    guard !entries.isEmpty else { return 0 }
    return Double(currentIndex + 1) / Double(entries.count)
  }
  
  var progressText: String {
    guard !entries.isEmpty else { return "0 / 0" }
    return "\(currentIndex + 1) / \(entries.count)"
  }
  
  var canGoPrevious: Bool {
    currentIndex > 0
  }
  
  var canGoNext: Bool {
    currentIndex < entries.count - 1
  }
  
  //  init(vocabulary: Vocabulary, entries: [VocabularyEntry]) {
  //    self.vocabulary = vocabulary
  //    self.entries = entries.shuffled()
  //  }
  
  func revealTranslation() {
    isTranslationRevealed = true
  }
  
  func nextEntry() {
    guard canGoNext else { return }
    currentIndex += 1
    isTranslationRevealed = false
  }
  
  func previousEntry() {
    guard canGoPrevious else { return }
    currentIndex -= 1
    isTranslationRevealed = false
  }
}
