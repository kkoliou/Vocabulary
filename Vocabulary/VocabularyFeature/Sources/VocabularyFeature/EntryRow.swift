//
//  EntryRow.swift
//  VocabularyFeature
//
//  Created by Konstantinos Kolioulis on 8/2/26.
//

import SwiftUI
import VocabularyDB

struct EntryRow: View {
  let entry: VocabularyEntry
  let onRemoveFromHighlights: () -> Void
  let onAddToHighlights: () -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(entry.sourceWord)
          .font(.headline)
          .foregroundColor(.primary)
        Spacer()
        if entry.isHighlighted {
          Image(systemName: "bookmark.fill")
            .foregroundColor(.yellow)
            .font(.caption)
        }
      }
      Text(entry.translatedWord)
        .font(.subheadline)
        .foregroundColor(.secondary)
    }
    .padding(.vertical, 4)
    .listRowBackground(entry.isHighlighted ? Color.yellow.opacity(0.1) : nil)
    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
      if entry.isHighlighted {
        Button(
          role: .destructive,
          action: onRemoveFromHighlights,
          label: {
            Label("Remove Highlight", systemImage: "bookmark.slash")
          }
        )
        .tint(.red)
      } else {
        Button(
          role: .destructive,
          action: onRemoveFromHighlights,
          label: {
            Label("Highlight", systemImage: "bookmark.fill")
          }
        )
        .tint(.yellow)
      }
    }
  }
}
