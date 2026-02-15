//
//  NavigationControlsView.swift
//  VocabularyModules
//
//  Created by Konstantinos Kolioulis on 15/2/26.
//

import SwiftUI

struct NavigationControlsView: View {
  let canGoPrevious: Bool
  let canGoNext: Bool
  let currentIndex: Int
  let totalCount: Int
  let onPrevious: () -> Void
  let onNext: () -> Void
  
  var body: some View {
    HStack(spacing: 20) {
      NavigationButton(
        direction: .previous,
        isEnabled: canGoPrevious,
        action: onPrevious
      )
      
      Spacer()
    
      NavigationButton(
        direction: .next,
        isEnabled: canGoNext,
        action: onNext
      )
    }
    .padding(.horizontal, 32)
    .padding(.vertical, 24)
  }
}

private struct NavigationButton: View {
  enum Direction {
    case previous
    case next
    
    var systemImage: String {
      switch self {
      case .previous: return "chevron.left"
      case .next: return "chevron.right"
      }
    }
  }
  
  let direction: Direction
  let isEnabled: Bool
  let action: () -> Void
  
  var body: some View {
    Button {
      guard isEnabled else { return }
      withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
        action()
      }
    } label: {
      ZStack {
        Circle()
          .fill(Color(.tertiarySystemGroupedBackground))
          .frame(width: 56, height: 56)
        
        Image(systemName: direction.systemImage)
          .font(.title3.weight(.semibold))
          .foregroundColor(isEnabled ? .primary : .secondary)
      }
    }
    .disabled(!isEnabled)
    .opacity(isEnabled ? 1.0 : 0.5)
  }
}
