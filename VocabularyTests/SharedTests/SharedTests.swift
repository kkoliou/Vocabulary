import Testing
import Foundation
@testable import Shared

@Test func isGreekStorefront_withGreekAlpha3CountryCode_returnsTrue() {
  #expect(AppRegion.isGreekStorefront(countryCode: "GRC") == true)
}

@Test func isGreekStorefront_withNonGreekCountryCode_returnsFalse() {
  #expect(AppRegion.isGreekStorefront(countryCode: "USA") == false)
}

@Test func isGreekStorefront_withGreekAlpha2CountryCode_returnsFalse() {
  // StoreKit's storefront country code is ISO 3166-1 alpha-3 ("GRC"), not alpha-2 ("GR").
  #expect(AppRegion.isGreekStorefront(countryCode: "GR") == false)
}

@Test func isGreekStorefront_withNilCountryCode_returnsFalse() {
  #expect(AppRegion.isGreekStorefront(countryCode: nil) == false)
}

@Test func isGreekRegion_withGreekAlpha2RegionCode_returnsTrue() {
  #expect(AppRegion.isGreekRegion(regionCode: "GR") == true)
}

@Test func isGreekRegion_withNonGreekRegionCode_returnsFalse() {
  #expect(AppRegion.isGreekRegion(regionCode: "US") == false)
}

@Test func isGreekRegion_withGreekAlpha3RegionCode_returnsFalse() {
  // Locale's region code is ISO 3166-1 alpha-2 ("GR"), not alpha-3 ("GRC").
  #expect(AppRegion.isGreekRegion(regionCode: "GRC") == false)
}

@Test func isGreekRegion_withNilRegionCode_returnsFalse() {
  #expect(AppRegion.isGreekRegion(regionCode: nil) == false)
}

@Test func appRegionClientIsGreece_whenOnlyStorefrontIsGreek_returnsTrue() async {
  let client = AppRegionClient(countryCode: { "GRC" }, regionCode: { "US" })
  #expect(await client.isGreece() == true)
}

@Test func appRegionClientIsGreece_whenOnlyRegionIsGreek_returnsTrue() async {
  let client = AppRegionClient(countryCode: { "USA" }, regionCode: { "GR" })
  #expect(await client.isGreece() == true)
}

@Test func appRegionClientIsGreece_whenNeitherIsGreek_returnsFalse() async {
  let client = AppRegionClient(countryCode: { "USA" }, regionCode: { "US" })
  #expect(await client.isGreece() == false)
}

@Test func datesDiff() async {
  #expect(Date().getDiffInDays(from: Date().addingTimeInterval(TimeInterval(-10 * 86400))) == 10)
  #expect(Date().getDiffInDays(from: Date().addingTimeInterval(TimeInterval(10 * 86400))) == -10)
}
