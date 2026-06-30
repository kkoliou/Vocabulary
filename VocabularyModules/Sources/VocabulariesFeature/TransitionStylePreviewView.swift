//
//  TransitionStylePreviewView.swift
//  VocabulariesFeature
//

import SwiftUI
import Shared

struct TransitionStylePreviewView: View {
  let mode: PracticeDisplayMode

  var body: some View {
    Group {
      switch mode {
      case .cards:
        StackedCardsPreview()
      case .buttons:
        SingleCardPreview()
      }
    }
    .frame(height: 140)
    .frame(maxWidth: .infinity)
    .id(mode)
  }
}

private struct StackedCardsPreview: View {
  @State private var isSwiped = false

  var body: some View {
    ZStack {
      cardShape
        .scaleEffect(0.86)
        .offset(x: 18)
        .opacity(0.5)
      cardShape
        .scaleEffect(0.93)
        .offset(x: 9)
        .opacity(0.75)
      cardShape
        .offset(x: isSwiped ? -90 : 0)
        .rotationEffect(.degrees(isSwiped ? -14 : 0))
        .opacity(isSwiped ? 0 : 1)
    }
    .onAppear {
      withAnimation(.easeInOut(duration: 1.1).delay(0.6).repeatForever(autoreverses: true)) {
        isSwiped = true
      }
    }
  }

  private var cardShape: some View {
    RoundedRectangle(cornerRadius: 16)
      .fill(Color(.secondarySystemGroupedBackground))
      .overlay(
        RoundedRectangle(cornerRadius: 16)
          .strokeBorder(Color(.separator), lineWidth: 1)
      )
      .frame(width: 90, height: 120)
  }
}

private struct SingleCardPreview: View {
  @State private var isPulsing = false

  var body: some View {
    HStack(spacing: 16) {
      arrowButton(systemImage: "chevron.left", isPulsing: false)

      RoundedRectangle(cornerRadius: 16)
        .fill(Color(.secondarySystemGroupedBackground))
        .frame(width: 90, height: 120)
        .shadow(color: .black.opacity(0.15), radius: 10, y: 6)

      arrowButton(systemImage: "chevron.right", isPulsing: isPulsing)
    }
    .onAppear {
      withAnimation(.easeInOut(duration: 0.55).delay(0.3).repeatForever(autoreverses: true)) {
        isPulsing = true
      }
    }
  }

  private func arrowButton(systemImage: String, isPulsing: Bool) -> some View {
    ZStack {
      Circle()
        .fill(Color(.tertiarySystemGroupedBackground))
        .frame(width: 36, height: 36)
      Image(systemName: systemImage)
        .font(AppTypography.callout.weight(.semibold))
    }
    .scaleEffect(isPulsing ? 1.15 : 1.0)
    .opacity(isPulsing ? 1.0 : 0.5)
  }
}

#Preview {
  VStack(spacing: 24) {
    TransitionStylePreviewView(mode: .cards)
    TransitionStylePreviewView(mode: .buttons)
  }
}
