// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

public struct VocabularyWord: Identifiable, Codable {
  public let id = UUID()
  public var source: String
  public var translated: String
  
  enum CodingKeys: String, CodingKey {
    case source, translated
  }
}

public class VocabularyCsvParser {
  enum ParseError: Error {
    case fileNotFound
    case invalidFormat
    case missingRequiredFields
  }
  
  /// Parse CSV file from a file path
  /// Expected CSV format: english,translation,example (header row optional)
  public static func parse(filePath: String) throws -> [VocabularyWord] {
    guard let data = try? String(contentsOfFile: filePath, encoding: .utf8) else {
      throw ParseError.fileNotFound
    }
    return try parse(csvString: data)
  }
  
  /// Parse CSV from a String
  public static func parse(csvString: String) throws -> [VocabularyWord] {
    var words: [VocabularyWord] = []
    let lines = csvString.components(separatedBy: .newlines)
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .filter { !$0.isEmpty }
    
    guard !lines.isEmpty else {
      return []
    }
    
    // Check if first line is a header (contains "source" or "translated")
    let startIndex = lines[0].lowercased().contains("source") ||
    lines[0].lowercased().contains("translated") ? 1 : 0
    
    for (index, line) in lines.enumerated() {
      guard index >= startIndex else { continue }
      
      let fields = parseCSVLine(line)
      
      guard fields.count >= 2 else {
        throw ParseError.missingRequiredFields
      }
      
      let source = fields[0].trimmingCharacters(in: .whitespaces)
      let translated = fields[1].trimmingCharacters(in: .whitespaces)
      
      let word = VocabularyWord(
        source: source,
        translated: translated,
      )
      words.append(word)
    }
    
    return words
  }
  
  /// Parse a single CSV line, handling quoted fields
  private static func parseCSVLine(_ line: String) -> [String] {
    var fields: [String] = []
    var currentField = ""
    var insideQuotes = false
    
    for char in line {
      if char == "\"" {
        insideQuotes.toggle()
      } else if char == "," && !insideQuotes {
        fields.append(currentField)
        currentField = ""
      } else {
        currentField.append(char)
      }
    }
    fields.append(currentField)
    
    return fields.map { field in
      var cleaned = field
      if cleaned.hasPrefix("\"") && cleaned.hasSuffix("\"") {
        cleaned = String(cleaned.dropFirst().dropLast())
      }
      return cleaned
    }
  }
}
