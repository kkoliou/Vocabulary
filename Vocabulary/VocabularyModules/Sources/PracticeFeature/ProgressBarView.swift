//
//  ProgressBarView.swift
//  VocabularyModules
//
//  Created by Konstantinos Kolioulis on 15/2/26.
//

import SwiftUI
import Shared

struct ProgressBarView: View {
  let progressText: String
  let vocabularyName: String
  let progress: Double
  
  var body: some View {
    VStack(spacing: 12) {
      HStack {
        Text(progressText)
          .font(AppTypography.subheadline.weight(.semibold))
          .foregroundStyle(.secondary)
        
        Spacer()
        
        Text(vocabularyName)
          .font(AppTypography.subheadline.weight(.medium))
          .foregroundStyle(.secondary)
      }
      
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          // Background track
          RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemGray5))
            .frame(height: 8)
          
          // Progress fill
          RoundedRectangle(cornerRadius: 8)
            .fill(Color.accentColor)
            .frame(width: geometry.size.width * progress, height: 8)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)
        }
      }
      .frame(height: 8)
    }
    .padding(.horizontal, 24)
    .padding(.top, 20)
    .padding(.bottom, 16)
  }
}

#Preview {
  ProgressBarView(progressText: "progressText", vocabularyName: "vocabularyName", progress: 0.4)
}
