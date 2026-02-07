//
//  Strings+.swift
//  Shared
//
//  Created by Konstantinos Kolioulis on 8/2/26.
//

import Foundation

public extension String {
  func trimmed() -> String {
    trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
