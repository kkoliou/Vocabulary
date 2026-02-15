//
//  EmptyStateView.swift
//  VocabularyModules
//
//  Created by Konstantinos Kolioulis on 15/2/26.
//

import SwiftUI
import Shared

struct EmptyStateView: View {
  var body: some View {
    VStack(spacing: 16) {
      Spacer()
      
      Image(systemName: "book.closed")
        .font(AppTypography.rounded(size: 60))
        .foregroundStyle(.tertiary)
      
      Text("No Entries")
        .font(AppTypography.title.weight(.semibold))
      
      Text("Add some vocabulary entries to practice")
        .font(AppTypography.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
      
      Spacer()
    }
    .padding(.horizontal, 40)
  }
}
