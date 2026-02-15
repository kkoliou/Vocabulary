//
//  VocabularyCardView.swift
//  VocabularyModules
//
//  Created by Konstantinos Kolioulis on 15/2/26.
//

import SwiftUI
import VocabularyDB
import SQLiteData

struct VocabularyCardView: View {
  let entry: VocabularyEntry
  let isTranslationRevealed: Bool
  let onRevealTranslation: () -> Void
  
  var body: some View {
    GeometryReader { geometry in
      VStack {
        Spacer()
        
        ZStack {
          RoundedRectangle(cornerRadius: 24)
            .fill(Color(.secondarySystemGroupedBackground))
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
          
          VStack(spacing: 0) {
            Spacer()
            
            SourceWordSection(sourceWord: entry.sourceWord)
            
            Spacer()

            CardDivider()
            
            Spacer()
            
            TranslationSection(
              translatedWord: entry.translatedWord,
              isRevealed: isTranslationRevealed,
              onReveal: onRevealTranslation
            )
            
            Spacer()
          }
          .padding(.vertical, 40)
        }
        .frame(height: min(geometry.size.height * 0.75, 500))
        .padding(.horizontal, 24)
        
        Spacer()
      }
    }
  }
}

private struct SourceWordSection: View {
  let sourceWord: String
  
  var body: some View {
    Text(sourceWord)
      .font(.system(size: 38, weight: .bold, design: .rounded))
      .multilineTextAlignment(.center)
      .foregroundColor(.primary)
      .padding(.horizontal, 32)
      .minimumScaleFactor(0.5)
      .lineLimit(3)
  }
}

private struct CardDivider: View {
  var body: some View {
    HStack(spacing: 12) {
      Rectangle()
        .fill(Color(.separator))
        .frame(height: 1)
      
      Image(systemName: "arrow.down")
        .font(.caption2)
        .foregroundStyle(.tertiary)
      
      Rectangle()
        .fill(Color(.separator))
        .frame(height: 1)
    }
    .padding(.horizontal, 60)
    .padding(.vertical, 24)
  }
}

private struct TranslationSection: View {
  let translatedWord: String
  let isRevealed: Bool
  let onReveal: () -> Void
  
  var body: some View {
    VStack(spacing: 16) {
      if isRevealed {
        Text(translatedWord)
          .font(.system(size: 32, weight: .semibold, design: .rounded))
          .multilineTextAlignment(.center)
          .foregroundStyle(.blue)
          .padding(.horizontal, 32)
          .minimumScaleFactor(0.5)
          .lineLimit(3)
          .transition(.asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .scale(scale: 0.9).combined(with: .opacity)
          ))
      } else {
        RevealButton(onReveal: onReveal)
      }
    }
    .frame(minHeight: 100)
  }
}

private struct RevealButton: View {
  let onReveal: () -> Void
  
  var body: some View {
    Button(action: onReveal) {
      HStack(spacing: 10) {
        Image(systemName: "eye.fill")
          .font(.callout)
        Text("Reveal Translation")
          .font(.callout.weight(.semibold))
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 12)
      .clipShape(.capsule)
      .shadow(color: .accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
    }
    .buttonStyle(.bordered)
    .transition(.scale(scale: 0.9).combined(with: .opacity))
  }
}

#Preview {
  RevealButton(onReveal: {})
}
