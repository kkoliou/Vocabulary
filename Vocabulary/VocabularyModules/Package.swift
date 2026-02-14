// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

var package = Package(
  name: "VocabularyModules",
  platforms: [
    .iOS(.v18)
  ],
  products: [
    // Shared/Core products
    .library(name: "Shared", targets: ["Shared"]),
    .library(name: "VocabularyDB", targets: ["VocabularyDB"]),
    .library(name: "VocabularyCsvParser", targets: ["VocabularyCsvParser"]),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/sqlite-data", from: "1.5.2"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.11.0")
  ],
  targets: [
    // MARK: - Shared/Core targets
    .target(
      name: "Shared"
    ),
    .testTarget(
      name: "SharedTests",
      dependencies: ["Shared"]
    ),
    .target(
      name: "VocabularyDB",
      dependencies: [
        .product(name: "SQLiteData", package: "sqlite-data")
      ]
    ),
    .testTarget(
      name: "VocabularyDBTests",
      dependencies: ["VocabularyDB"]
    ),
    .target(
      name: "VocabularyCsvParser"
    ),
    .testTarget(
      name: "VocabularyCsvParserTests",
      dependencies: ["VocabularyCsvParser"]
    ),
  ]
)

// MARK: - Feature modules
package.products.append(contentsOf: [
  .library(name: "VocabularyFeature", targets: ["VocabularyFeature"]),
  .library(name: "VocabulariesFeature", targets: ["VocabulariesFeature"]),
])

package.targets.append(contentsOf: [
  .target(
    name: "VocabularyFeature",
    dependencies: [
      "VocabularyDB",
      "Shared",
      "VocabularyCsvParser"
    ]
  ),
  .testTarget(
    name: "VocabularyFeatureTests",
    dependencies: [
      "VocabularyFeature",
      .product(name: "DependenciesTestSupport", package: "swift-dependencies")
    ]
  ),
  .target(
    name: "VocabulariesFeature",
    dependencies: [
      "VocabularyDB",
      "Shared",
      "VocabularyFeature"
    ]
  ),
  .testTarget(
    name: "VocabulariesFeatureTests",
    dependencies: [
      "VocabulariesFeature",
      .product(name: "DependenciesTestSupport", package: "swift-dependencies")
    ]
  ),
])
