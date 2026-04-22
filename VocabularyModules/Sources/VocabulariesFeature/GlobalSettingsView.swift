//
//  PracticeAppearanceSettingsView.swift
//  VocabulariesFeature
//

import SwiftUI
import Shared

struct GlobalSettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @Binding var displayMode: PracticeDisplayMode

  var body: some View {
    NavigationStack {
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
      }
      .navigationTitle(Strings.localized("Settings"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(
            action: { dismiss() },
            label: {
              Image(systemName: "xmark")
            }
          )
        }
      }
    }
  }
}

#Preview {
  GlobalSettingsView(displayMode: .constant(.cards))
}
