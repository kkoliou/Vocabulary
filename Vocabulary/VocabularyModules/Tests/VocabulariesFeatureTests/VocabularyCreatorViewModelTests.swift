//
//  VocabularyCreatorViewModelTests.swift
//  VocabulariesFeature
//
//  Created by Konstantinos Kolioulis on 14/2/26.
//

import Foundation
import SQLiteData
import Testing
import SQLiteData
import VocabularyDB
import Shared
import DependenciesTestSupport

@testable import VocabulariesFeature

extension BaseSuite {
  @Suite(
    .dependencies {
      try $0.defaultDatabase.write { db in
        try db.seed {
          Vocabulary.Draft(name: "Spanish", createdAt: Date())
          Vocabulary.Draft(name: "French", createdAt: Date())
        }
      }
    }
  )
  @MainActor
  struct VocabularyCreatorViewModelTests {
    let model: VocabularyCreatorViewModel
    @Dependency(\.defaultDatabase) var database
    
    init() async throws {
      model = VocabularyCreatorViewModel()
    }
    
    @Test func addVocabularyWithValidName() async throws {
      model.addVocabularyTapped(vocabName: "German")
      
      #expect(model.triggerSuccess == true)
      #expect(model.dismiss == true)
      #expect(model.alertIsPresented == false)
      
      // Verify it was actually inserted into the database
      let exists = try await database.read { db in
        try Vocabulary
          .where { $0.name.eq("German") }
          .fetchCount(db) > 0
      }
      #expect(exists == true)
    }
    
    @Test func addVocabularyWithEmptyName() async throws {
      model.addVocabularyTapped(vocabName: "")
      
      #expect(model.triggerSuccess == false)
      #expect(model.dismiss == false)
      #expect(model.alertIsPresented == true)
      #expect(model.alertTitle == Strings.localized("Provide a vocabulary name"))
      
      // Verify nothing was inserted
      let count = try await database.read { db in
        try Vocabulary.fetchCount(db)
      }
      #expect(count == 2) // Only the seeded vocabularies
    }
    
    @Test func addVocabularyWithWhitespaceOnlyName() async throws {
      model.addVocabularyTapped(vocabName: "   ")
      
      #expect(model.triggerSuccess == false)
      #expect(model.dismiss == false)
      #expect(model.alertIsPresented == true)
      #expect(model.alertTitle == Strings.localized("Provide a vocabulary name"))
    }
    
    @Test func addVocabularyWithLeadingAndTrailingWhitespace() async throws {
      model.addVocabularyTapped(vocabName: "  Italian  ")
      
      #expect(model.triggerSuccess == true)
      #expect(model.dismiss == true)
      
      // Verify it was trimmed before insertion
      let exists = try await database.read { db in
        try Vocabulary
          .where { $0.name.eq("Italian") }
          .fetchCount(db) > 0
      }
      #expect(exists == true)
    }
    
    @Test func addVocabularyThatAlreadyExists() async throws {
      model.addVocabularyTapped(vocabName: "Spanish")
      
      #expect(model.triggerSuccess == false)
      #expect(model.dismiss == false)
      #expect(model.alertIsPresented == true)
      #expect(model.alertTitle == Strings.localized("The vocabulary already exists"))
      
      // Verify only one Spanish vocabulary exists
      let count = try await database.read { db in
        try Vocabulary
          .where { $0.name.eq("Spanish") }
          .fetchCount(db)
      }
      #expect(count == 1)
    }
    
    @Test func addVocabularyWithDifferentCasing() async throws {
      // This test checks if "spanish" is treated differently from "Spanish"
      // Adjust based on your business logic requirements
      model.addVocabularyTapped(vocabName: "spanish")
      
      let exists = try await database.read { db in
        try Vocabulary
          .where { $0.name.eq("spanish") }
          .fetchCount(db) > 0
      }
      #expect(exists == true)
      #expect(model.triggerSuccess == true)
    }
    
    @Test func addMultipleVocabulariesInSequence() async throws {
      let model1 = VocabularyCreatorViewModel()
      model1.addVocabularyTapped(vocabName: "Portuguese")
      #expect(model1.triggerSuccess == true)
      
      let model2 = VocabularyCreatorViewModel()
      model2.addVocabularyTapped(vocabName: "Japanese")
      #expect(model2.triggerSuccess == true)
      
      let count = try await database.read { db in
        try Vocabulary.fetchCount(db)
      }
      #expect(count == 4) // 2 seeded + 2 new
    }
    
    @Test func addVocabularyNameWithSpecialCharacters() async throws {
      model.addVocabularyTapped(vocabName: "中文")
      
      #expect(model.triggerSuccess == true)
      #expect(model.dismiss == true)
      
      let exists = try await database.read { db in
        try Vocabulary
          .where { $0.name.eq("中文") }
          .fetchCount(db) > 0
      }
      #expect(exists == true)
    }
    
    @Test func addVocabularyWithLongName() async throws {
      let longName = String(repeating: "a", count: 100)
      model.addVocabularyTapped(vocabName: longName)
      
      #expect(model.triggerSuccess == true)
      
      let exists = try await database.read { db in
        try Vocabulary
          .where { $0.name.eq(longName) }
          .fetchCount(db) > 0
      }
      #expect(exists == true)
    }
  }
}

@Suite(
  .dependencies {
    $0.uuid = .incrementing
    try $0.bootstrapDatabase()
  }
)
struct BaseSuite {}
