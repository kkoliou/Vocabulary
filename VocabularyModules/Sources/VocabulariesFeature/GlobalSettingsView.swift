//
//  GlobalSettingsView.swift
//  VocabulariesFeature
//

import SwiftUI
import Shared

struct GlobalSettingsView: View {
  let onSelectPracticeDisplay: () -> Void
  let onSelectLanguage: () -> Void

  var body: some View {
    List {
      row(title: Strings.localized("Practice Style")) {
        onSelectPracticeDisplay()
      }

      row(title: Strings.localized("Language")) {
        onSelectLanguage()
      }
    }
    .navigationTitle(Strings.localized("Settings"))
  }

  private func row(
    title: LocalizedStringResource,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      rowLabel(title: title)
    }
    .buttonStyle(.automatic)
    .tint(.primary)
  }

  private func rowLabel(title: LocalizedStringResource) -> some View {
    HStack(spacing: 12) {
      Text(title)
        .font(AppTypography.body.weight(.regular))
        .foregroundStyle(.primary)
      Spacer()
      Image(systemName: "chevron.right")
        .font(AppTypography.footnote.weight(.semibold))
        .foregroundStyle(.secondary)
    }
    .contentShape(Rectangle())
  }
}

#Preview {
  NavigationStack {
    GlobalSettingsView(
      onSelectPracticeDisplay: {},
      onSelectLanguage: {}
    )
  }
}
