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
