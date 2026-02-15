import SwiftUI

public enum AppTypography {
  // Sized rounded font helper
  public static func rounded(size: CGFloat, weight: Font.Weight = .regular) -> Font {
    .system(size: size, weight: weight, design: .rounded)
  }
  
  // Text styles with rounded design
  public static var largeTitle: Font { .system(.largeTitle, design: .rounded) }
  public static var title: Font { .system(.title2, design: .rounded) }
  public static var title3: Font { .system(.title3, design: .rounded) }
  public static var headline: Font { .system(.headline, design: .rounded) }
  public static var subheadline: Font { .system(.subheadline, design: .rounded) }
  public static var body: Font { .system(.body, design: .rounded) }
  public static var callout: Font { .system(.callout, design: .rounded) }
  public static var footnote: Font { .system(.footnote, design: .rounded) }
  public static var caption: Font { .system(.caption, design: .rounded) }
  public static var caption2: Font { .system(.caption2, design: .rounded) }
}
