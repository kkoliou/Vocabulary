//
//  EmptyStateView.swift
//  VocabularyModules
//
//  Created by Konstantinos Kolioulis on 15/2/26.
//

import SwiftUI

struct EmptyStateView: View {
  var body: some View {
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
}
