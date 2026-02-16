//
//  RandomnessSettingsView.swift
//  VocabularyModules
//
//  Created by Konstantinos Kolioulis on 16/2/26.
//

import SwiftUI
import VocabularyDB
import SQLiteData
import Shared

struct RandomnessSettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var probability: Double
  let onApply: (Double) -> Void
  
  init(
    probability: Double,
    onApply: @escaping (Double) -> Void
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
            Text(probabilityLabel)
              .font(AppTypography.subheadline)
              .foregroundStyle(.secondary)
          }
          .padding(.vertical, 8)
        } header: {
          Text("Hidden Word Randomness")
        } footer: {
          Text("Adjust the probability that the original word (vs translation) will be hidden. 50% means equal chance for each.")
        }
      }
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(
            action: {
              onApply(probability)
              let generator = UIImpactFeedbackGenerator(style: .light)
              generator.impactOccurred()
              dismiss()
            },
            label: {
              Image(systemName: "checkmark")
            }
          )
        }
      }
    }
  }
  
  private var probabilityLabel: String {
    let percent = Int(probability * 100)
    switch percent {
    case 0:
      return "Always hide translation"
    case 100:
      return "Always hide original"
    default:
      return "\(percent)% chance to hide original"
    }
  }
}
