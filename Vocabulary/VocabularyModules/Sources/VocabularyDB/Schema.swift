//
//  Schema.swift
//  VocabularyDB
//
//  Created by Konstantinos Kolioulis on 21/1/26.
//

import SwiftUI
import SQLiteData

@Table public struct Vocabulary: Identifiable, Sendable, Hashable {
  public let id: UUID
  public var name: String
  public let createdAt: Date
}

@Table public struct VocabularyEntry: Identifiable, Sendable, Equatable {
  public let id: UUID
  public let vocabularyID: Vocabulary.ID
  public var sourceWord: String
  public var translatedWord: String
  public var sourceLanguageCode: String?
  public var targetLanguageCode: String?
  public var isHighlighted: Bool
}

func appDatabase() throws -> any DatabaseWriter {
  let database = try SQLiteData.defaultDatabase()
  var migrator = DatabaseMigrator()
  
  #if DEBUG
  migrator.eraseDatabaseOnSchemaChange = true
  #endif
  
  migrator.registerMigration("Create vocabularies and vocabularyEntries") { db in
    try #sql(
        """
        CREATE TABLE "vocabularies" (
            "id" TEXT PRIMARY KEY NOT NULL
                ON CONFLICT REPLACE
                DEFAULT (uuid()),
            "name" TEXT NOT NULL DEFAULT '',
            "createdAt" TEXT NOT NULL
                DEFAULT (CURRENT_TIMESTAMP)
        ) STRICT
        """
    )
    .execute(db)
    
    try #sql(
        """
        CREATE TABLE "vocabularyEntries" (
            "id" TEXT PRIMARY KEY NOT NULL
                ON CONFLICT REPLACE
                DEFAULT (uuid()),
            "vocabularyID" TEXT NOT NULL
                REFERENCES "vocabularies"("id")
                ON DELETE CASCADE,
            "sourceWord" TEXT NOT NULL DEFAULT '',
            "translatedWord" TEXT NOT NULL DEFAULT '',
            "sourceLanguageCode" TEXT,
            "targetLanguageCode" TEXT,
            "isHighlighted" INTEGER NOT NULL DEFAULT 0
        ) STRICT
        """
    )
    .execute(db)
    
    try #sql(
        """
        CREATE INDEX idx_vocabularyEntries_vocabularyID
        ON vocabularyEntries(vocabularyID)
        """
    )
    .execute(db)
  }
  
  try migrator.migrate(database)
  return database
}

extension DependencyValues {
  mutating public func bootstrapDatabase() throws {
    defaultDatabase = try appDatabase()
  }
}

extension DatabaseWriter {
  public func seed() throws {
    let flagKey = "db_initialized"
    let isFirstLaunch = !UserDefaults.standard.bool(forKey: flagKey)
    guard isFirstLaunch else { return }
    try write { db in
      try db.seed {
        Vocabulary(id: UUID(), name: "Vocabulary 1", createdAt: Date(timeIntervalSince1970: 1719869724))
        Vocabulary(id: UUID(), name: "Vocabulary 2", createdAt: Date())
      }
    }
    UserDefaults.standard.set(true, forKey: flagKey)
  }
  
  public func seedForPreview() throws {
    try deleteAllVocabularies()
    try write { db in
      try db.seed {
        Vocabulary(id: UUID(), name: "Vocabulary 1", createdAt: Date(timeIntervalSince1970: 1719869724))
        Vocabulary(id: UUID(), name: "Vocabulary 2", createdAt: Date())
      }
    }
  }
  
  public func deleteAllVocabularies() throws {
    try write { db in
      try Vocabulary
        .delete()
        .execute(db)
    }
  }
}
