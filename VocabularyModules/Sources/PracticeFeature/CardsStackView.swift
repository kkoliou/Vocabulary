//
//  CardsStackView.swift
//  VocabularyModules
//
//  Created by Konstantinos Kolioulis on 3/4/26.
//

import SwiftUI
import SQLiteData
import VocabularyDB

struct CardsStackView: View {
  let practiceRows: [PracticeRow]
  let currentIndex: Int
  @Binding var isTranslationRevealed: Bool
  let onRevealTranslation: () -> Void
  let onIndexChanged: (Int) -> Void

  @State private var localIndex = 0
  @State private var dragProgress: CGFloat = 0
  @GestureState private var isDragActive = false

  private let neighborLimit = 3
  private let deckScale: CGFloat = 0.92

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        ForEach(windowIndices, id: \.self) { index in
          card(for: index)
            .zIndex(zIndex(for: index))
            .offset(x: xOffset(for: index, width: geometry.size.width))
            .scaleEffect(scale(for: index))
            .rotationEffect(.degrees(rotation(for: index)))
            .shadow(color: shadow(for: index), radius: 10, y: 6)
        }
      }
      .scaleEffect(deckScale)
      .contentShape(Rectangle())
      .highPriorityGesture(dragGesture(width: geometry.size.width))
    }
    .task {
      localIndex = currentIndex
    }
    .onChange(of: currentIndex) { _, newValue in
      guard newValue != localIndex else { return }
      localIndex = newValue
    }
    .onChange(of: isDragActive) { _, active in
      guard !active, dragProgress != 0 else { return }
      withAnimation(.bouncy) {
        dragProgress = 0
      }
    }
  }

  private var maxIndex: Int {
    practiceRows.count - 1
  }

  private var windowIndices: [Int] {
    let lowerBound = max(0, localIndex - neighborLimit)
    let upperBound = min(maxIndex, localIndex + neighborLimit)
    guard lowerBound <= upperBound else { return [] }
    return Array(lowerBound...upperBound)
  }

  private func card(for index: Int) -> some View {
    VocabularyCardView(
      practiceData: practiceRows[index],
      isTranslationRevealed: index == localIndex ? isTranslationRevealed : false,
      onRevealTranslation: {
        guard index == localIndex else { return }
        onRevealTranslation()
      },
      isForStack: true
    )
  }

  private func dragGesture(width: CGFloat) -> some Gesture {
    DragGesture(minimumDistance: 5)
      .updating($isDragActive) { _, state, _ in
        state = true
      }
      .onChanged { value in
        guard width > 0 else { return }
        var progress = -(value.translation.width / width)
        if progress > 0, localIndex >= maxIndex {
          progress = 0
        }
        if progress < 0, localIndex <= 0 {
          progress = 0
        }
        dragProgress = progress
      }
      .onEnded { value in
        snapToNearestIndex(velocity: value.velocity.width)
      }
  }

  private func snapToNearestIndex(velocity: CGFloat = 0) {
    let distanceThreshold: CGFloat = 0.3
    let velocityThreshold: CGFloat = 500

    let distanceDirection = dragProgress < 0 ? -1 : 1
    let velocityDirection = velocity < 0 ? 1 : -1

    let triggeredByDistance = abs(dragProgress) >= distanceThreshold
    let triggeredByVelocity = abs(velocity) >= velocityThreshold

    guard triggeredByDistance || triggeredByVelocity else {
      withAnimation(.bouncy) {
        dragProgress = 0
      }
      return
    }

    let effectiveDirection = triggeredByDistance ? distanceDirection : velocityDirection
    let newIndex = localIndex + effectiveDirection

    guard newIndex >= 0, newIndex <= maxIndex else {
      withAnimation(.bouncy) {
        dragProgress = 0
      }
      return
    }

    withAnimation(.smooth(duration: 0.25)) {
      localIndex = newIndex
      dragProgress = 0
    }
    onIndexChanged(newIndex)
  }

  // MARK: - Geometry

  private var progressIndex: CGFloat {
    CGFloat(localIndex) + dragProgress
  }

  private func currentPosition(for index: Int) -> CGFloat {
    progressIndex - CGFloat(index)
  }

  private func zIndex(for index: Int) -> Double {
    Double(-abs(currentPosition(for: index)))
  }

  private func xOffset(for index: Int, width: CGFloat) -> CGFloat {
    let padding = width / 10
    let x = (CGFloat(index) - progressIndex) * padding
    if index == localIndex, progressIndex > 0, progressIndex < CGFloat(maxIndex) {
      return x * swingOutMultiplier
    }
    return x
  }

  private var swingOutMultiplier: CGFloat {
    abs(sin(.pi * progressIndex) * 20)
  }

  private func scale(for index: Int) -> CGFloat {
    1 - (0.1 * abs(currentPosition(for: index)))
  }

  private func rotation(for index: Int) -> Double {
    Double(-currentPosition(for: index) * 2)
  }

  private func shadow(for index: Int) -> Color {
    let progress = 1 - abs(progressIndex - CGFloat(index))
    let opacity = 0.1 * progress
    return .black.opacity(max(0, opacity))
  }
}
