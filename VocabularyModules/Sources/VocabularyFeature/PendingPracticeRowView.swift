//
//  PendingPracticeRowView.swift
//  VocabularyModules
//
//  Created by Konstantinos Kolioulis on 18/2/26.
//

import SwiftUI
import Shared

struct PendingPracticeRowView: View {
  let title: String
  let lastStoppedPosition: Int
  let totalEntries: Int
  
  var body: some View {
    HStack {
      Image(systemName: "brain.head.profile")
        .foregroundColor(.accentColor)
      VStack(alignment: .leading) {
        Text(title)
          .font(AppTypography.body)
        Text("\(lastStoppedPosition) / \(totalEntries)")
          .font(AppTypography.caption)
          .foregroundColor(.secondary)
      }
      Spacer()
    }
  }
}

#Preview {
  PendingPracticeRowView(title: "18/2/26", lastStoppedPosition: 10, totalEntries: 100)
}
