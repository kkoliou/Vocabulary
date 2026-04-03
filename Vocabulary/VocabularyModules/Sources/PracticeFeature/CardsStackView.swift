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
  let items: [String]
  
  var body: some View {
    GeometryReader {
      let size = $0.size
      ScrollView(.horizontal) {
        LazyHStack(spacing: 0) {
          ForEach(Array(items.enumerated()), id: \.offset) { index, item in
            card
              .padding(.horizontal,80)
              .frame(width: size.width)
              .visualEffect { content, geometry in
                content
                  .scaleEffect(scale(for: geometry), anchor: .trailing)
                  .rotationEffect(rotation(for: geometry))
                  .offset(x: clampedMinX(for: geometry))
                  .offset(x: excessMinX(for: geometry))
              }
              .zIndex(zIndex(index))
          }
        }
        .padding(.vertical, 15)
      }
      .scrollTargetBehavior(.paging)
      .scrollIndicators(.hidden)
    }
    .frame(height: 410)
  }
  
  private var card: some View {
    RoundedRectangle(cornerRadius: 16)
      .fill([Color.blue, .black, .green, .brown, .red].randomElement()!)
  }
  
  private func zIndex(_ index: Int) -> CGFloat {
    return CGFloat(items.count - index)
  }
  
  nonisolated private func clampedMinX(for geometry: GeometryProxy) -> CGFloat {
    let minX = geometry.frame(in: .scrollView(axis: .horizontal)).minX
    return minX < 0 ? 0 : -minX
  }
  
  nonisolated private func progress(for geometry: GeometryProxy, limit: CGFloat = 3) -> CGFloat {
    let maxX = geometry.frame(in: .scrollView(axis: .horizontal)).maxX
    let width = geometry.bounds(of: .scrollView(axis: .horizontal))?.width ?? 0
    let progress = (maxX / width) - 1.0
    let cappedProgress = min(progress, limit)
    return cappedProgress
  }
  
  nonisolated private func scale(for geometry: GeometryProxy, scale: CGFloat = 0.1) -> CGFloat {
    let progress = progress(for: geometry)
    return 1 - (progress * scale)
  }
  
  nonisolated private func excessMinX(for geometry: GeometryProxy, offset: CGFloat = 10) -> CGFloat {
    let progress = progress(for: geometry)
    return progress * offset
  }
  
  nonisolated private func rotation(for geometry: GeometryProxy, rotation: CGFloat = 2) -> Angle {
    let progress = progress(for: geometry)
    return .init(degrees: progress * rotation)
  }

}

#Preview {
  CardsStackView(items: ["aek", "aek", "aek", "aek", "aek", "aek", "aek", "aek", "aek", "aek"])
}
