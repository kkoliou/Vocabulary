import Testing
@testable import Shared

@Test func isGreece_withGreekAlpha3CountryCode_returnsTrue() {
  #expect(AppStorefront.isGreece(countryCode: "GRC") == true)
}

@Test func isGreece_withNonGreekCountryCode_returnsFalse() {
  #expect(AppStorefront.isGreece(countryCode: "USA") == false)
}

@Test func isGreece_withGreekAlpha2CountryCode_returnsFalse() {
  // StoreKit's storefront country code is ISO 3166-1 alpha-3 ("GRC"), not alpha-2 ("GR").
  #expect(AppStorefront.isGreece(countryCode: "GR") == false)
}

@Test func isGreece_withNilCountryCode_returnsFalse() {
  #expect(AppStorefront.isGreece(countryCode: nil) == false)
}
