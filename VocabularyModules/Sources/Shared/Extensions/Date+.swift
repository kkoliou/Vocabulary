//
//  Date+.swift
//  VocabularyModules
//
//  Created by Konstantinos Kolioulis on 13/7/26.
//

import Foundation

public extension Date {
  
  func getDiffInDays(from date: Date) -> Int {
    Calendar.current.dateComponents(
      [.day],
      from: date,
      to: self
    ).day ?? 0
  }
  
}
