//
//  EntryRowView.swift
//  VocabularyFeature
//
//  Created by Konstantinos Kolioulis on 8/2/26.
//

import SwiftUI
import VocabularyDB
import SQLiteData
import Shared

struct EntryRowView: View {
  let entry: VocabularyEntry
  let onRemoveFromHighlights: () -> Void
  let onAddToHighlights: () -> Void
  let onEdit: () -> Void
  let onDelete: () -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(entry.sourceWord)
          .font(AppTypography.headline.weight(.semibold))
          .foregroundColor(.primary)
        Spacer()
        if entry.isHighlighted {
          Image(systemName: "bookmark.fill")
            .foregroundColor(Color.accentColor)
            .font(AppTypography.caption)
        }
      }
      Text(entry.translatedWord)
        .font(AppTypography.subheadline)
        .foregroundColor(.secondary)
    }
    .padding(.vertical, 4)
    .listRowBackground(entry.isHighlighted ? AppColors.accentLight.opacity(0.25) : nil)
    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
      if entry.isHighlighted {
        Button(
          role: .cancel,
          action: onRemoveFromHighlights,
          label: {
            Label("Remove Highlight", systemImage: "bookmark.slash")
          }
        )
        .tint(AppColors.accent)
      } else {
        Button(
          role: .cancel,
          action: onAddToHighlights,
          label: {
            Label("Highlight", systemImage: "bookmark.fill")
          }
        )
        .tint(AppColors.accent)
      }
      
      Menu {
        Button(action: onEdit) {
          Label("Edit", systemImage: "pencil")
        }
        Button(role: .destructive, action: onDelete) {
          Label("Delete", systemImage: "trash")
        }
      } label: {
        Image(systemName: "ellipsis")
          .font(AppTypography.body)
      }
    }
  }
}

#Preview {
  let entry = prepareDependencies {
    try! $0.bootstrapDatabase()
    try! $0.defaultDatabase.write { db in
      try! db.seed {
        let vocabId = UUID()
        Vocabulary.Draft(
          id: vocabId,
          name: "Vocabulary 1",
          createdAt: Date(timeIntervalSince1970: 1719869724)
        )
        VocabularyEntry.Draft(
          vocabularyID: vocabId,
          sourceWord: "source",
          translatedWord: "translation",
          isHighlighted: false
        )
      }
    }
    return try! $0.defaultDatabase.read { db in
      try VocabularyEntry.fetchOne(db)!
    }
  }
  EntryRowView(entry: entry, onRemoveFromHighlights: {}, onAddToHighlights: {}, onEdit: {}, onDelete: {})
}
