//
//  Schema.swift
//  VocabularyDB
//
//  Created by Konstantinos Kolioulis on 21/1/26.
//

import SwiftUI
import SQLiteData

@Table public struct Vocabulary: Identifiable, Sendable {
  public let id: UUID
  public var name: String
}

@Table public struct VocabularyEntry: Identifiable, Sendable {
  public let id: UUID
  public let vocabularyID: Vocabulary.ID
  public var sourceWord: String
  public var translatedWord: String
  public var sourceLanguageCode: String?
  public var targetLanguageCode: String?
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
            "name" TEXT NOT NULL DEFAULT ''
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
            "targetLanguageCode" TEXT
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
