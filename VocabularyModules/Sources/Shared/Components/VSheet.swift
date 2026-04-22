//
//  VSheet.swift
//  Shared
//
//  Created by Konstantinos Kolioulis on 8/2/26.
//

import SwiftUI

public struct VSheet<SheetContent: View>: ViewModifier {
  
  @Binding var isPresented: Bool
  let sheetContent: () -> SheetContent
  
  public init(
    isPresented: Binding<Bool>,
    @ViewBuilder sheetContent: @escaping () -> SheetContent
  ) {
    self._isPresented = isPresented
    self.sheetContent = sheetContent
  }
  
  public func body(content: Content) -> some View {
    content
      .sheet(isPresented: $isPresented) {
        sheetContent()
          .presentationDragIndicator(.visible)
      }
  }
}

public extension View {
  func vSheet<Content: View>(
    isPresented: Binding<Bool>,
    @ViewBuilder content: @escaping () -> Content
  ) -> some View {
    modifier(
      VSheet(
        isPresented: isPresented,
        sheetContent: content
      )
    )
  }
}

public extension View {
  func defaultPresentationDetents() -> some View {
    self.presentationDetents([.fraction(0.7)])
  }
  
  func largePresentationDetents() -> some View {
    self.presentationDetents([.large])
  }
  
  func smallPresentationDetents() -> some View {
    self.presentationDetents([.fraction(0.4)])
  }
}
