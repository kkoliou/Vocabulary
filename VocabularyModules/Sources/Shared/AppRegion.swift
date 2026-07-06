//
//  AppRegion.swift
//  Shared
//
//  Created by Konstantinos Kolioulis on 6/7/26.
//

import Dependencies
import Foundation
import StoreKit

public enum AppRegion {
  public static func isGreekStorefront(countryCode: String?) -> Bool {
    countryCode == "GRC"
  }

  public static func isGreekRegion(regionCode: String?) -> Bool {
    regionCode == "GR"
  }
}

public struct AppRegionClient: Sendable {
  public var countryCode: @Sendable () async -> String?
  public var regionCode: @Sendable () -> String?

  public init(
    countryCode: @escaping @Sendable () async -> String?,
    regionCode: @escaping @Sendable () -> String? = { nil }
  ) {
    self.countryCode = countryCode
    self.regionCode = regionCode
  }

  public func isGreece() async -> Bool {
    AppRegion.isGreekStorefront(countryCode: await countryCode())
      || AppRegion.isGreekRegion(regionCode: regionCode())
  }
}

extension AppRegionClient: DependencyKey {
  public static let liveValue = AppRegionClient(
    countryCode: { await Storefront.current?.countryCode },
    regionCode: { Locale.current.region?.identifier }
  )

  public static let testValue = AppRegionClient(
    countryCode: { nil },
    regionCode: { nil }
  )
}

extension DependencyValues {
  public var appRegion: AppRegionClient {
    get { self[AppRegionClient.self] }
    set { self[AppRegionClient.self] = newValue }
  }
}
