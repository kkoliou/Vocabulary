//
//  VTextField.swift
//  Shared
//
//  Created by Konstantinos Kolioulis on 8/2/26.
//

import SwiftUI

public struct VTextField: View {
  @Binding var text: String
  let promptKey: StaticString
  
  public init(text: Binding<String>, promptKey: StaticString) {
    self._text = text
    self.promptKey = promptKey
  }
  
  public var body: some View {
    TextField(
      text: $text,
      prompt: Text(Strings.localized(promptKey)),
      label: {
        EmptyView()
      }
    )
    .font(AppTypography.body)
  }
}

#Preview {
  VTextField(text: .constant(""), promptKey: "Placeholder")
}
