//
//  PracticeDisplaySettingsView.swift
//  VocabulariesFeature
//

import SwiftUI
import Shared

struct PracticeDisplaySettingsView: View {
  @Binding var displayMode: PracticeDisplayMode

  var body: some View {
    List {
      Section {
        ForEach(PracticeDisplayMode.allCases) { mode in
          Button {
            displayMode = mode
          } label: {
            HStack(spacing: 12) {
              Text(mode.title)
              Spacer()
              if mode == displayMode {
                Image(systemName: "checkmark")
                  .font(AppTypography.body.weight(.semibold))
                  .foregroundStyle(.tint)
              }
            }
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
        }
      } header: {
        Text(Strings.localized("Choose how entries are shown while you practice."))
      }

      Section {
        TransitionStylePreviewView(mode: displayMode)
          .listRowInsets(EdgeInsets())
          .listRowBackground(Color.clear)
          .padding(.vertical, 12)
      }
    }
    .navigationTitle(Strings.localized("Practice Style"))
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  NavigationStack {
    PracticeDisplaySettingsView(displayMode: .constant(.cards))
  }
}
