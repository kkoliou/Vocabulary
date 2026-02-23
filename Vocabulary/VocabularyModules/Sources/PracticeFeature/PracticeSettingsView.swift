//
//  PracticeSettingsView.swift
//  VocabularyModules
//
//  Created by Konstantinos Kolioulis on 16/2/26.
//

import SwiftUI
import VocabularyDB
import SQLiteData
import Shared

struct PracticeSettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var probability: Double
  let onApply: (Double) async -> Void
  @State private var isLoading = false
  
  init(
    probability: Double,
    onApply: @escaping (Double) async -> Void
  ) {
    _probability = State(initialValue: probability)
    self.onApply = onApply
  }
  
  var body: some View {
    NavigationStack {
      Form {
        Section {
          VStack(alignment: .leading, spacing: 8) {
            Slider(value: $probability, in: 0...1, step: 0.1)
              .disabled(isLoading)
            Text(probabilityLabel)
              .font(AppTypography.subheadline)
              .foregroundStyle(.secondary)
          }
          .padding(.vertical, 8)
        } header: {
          Text(Strings.localized("Hidden Word Randomness"))
        } footer: {
          Text(Strings.localized("Adjust the probability that the original word (vs translation) will be hidden. 50% means equal chance for each."))
        }
      }
      .navigationTitle(Strings.localized("Settings"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(
            action: {
              Task {
                isLoading = true
                await onApply(probability)
                isLoading = false
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                dismiss()
              }
            },
            label: {
              if isLoading {
                ProgressView()
              } else {
                Image(systemName: "checkmark")
              }
            }
          )
        }
      }
    }
    .interactiveDismissDisabled(isLoading)
  }
  
  private var probabilityLabel: LocalizedStringResource {
    let percent = Int(probability * 100)
    switch percent {
    case 0:
      return Strings.localized("Always hide translation")
    case 100:
      return Strings.localized("Always hide original")
    default:
      return "\(percent)% \(Strings.localized("chance to hide original"))"
    }
  }
}
