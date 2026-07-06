//
//  AppStorefront.swift
//  Shared
//
//  Created by Konstantinos Kolioulis on 6/7/26.
//

import Dependencies
import StoreKit

public enum AppStorefront {
  public static func isGreece(countryCode: String?) -> Bool {
    countryCode == "GRC"
  }
}

public struct AppStorefrontClient: Sendable {
  public var countryCode: @Sendable () async -> String?

  public init(countryCode: @escaping @Sendable () async -> String?) {
    self.countryCode = countryCode
  }

  public func isGreece() async -> Bool {
    AppStorefront.isGreece(countryCode: await countryCode())
  }
}

extension AppStorefrontClient: DependencyKey {
  public static let liveValue = AppStorefrontClient(
    countryCode: { await Storefront.current?.countryCode }
  )

  public static let testValue = AppStorefrontClient(
    countryCode: { nil }
  )
}

extension DependencyValues {
  public var appStorefront: AppStorefrontClient {
    get { self[AppStorefrontClient.self] }
    set { self[AppStorefrontClient.self] = newValue }
  }
}
