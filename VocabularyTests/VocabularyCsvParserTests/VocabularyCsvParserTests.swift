import Testing
@testable import VocabularyCsvParser

// MARK: - Basic Parsing Tests

struct VocabularyCsvParserTests {
  
  @Test func parseSimpleCSV() throws {
    let csv = """
    hello,hola
    goodbye,adiós
    thank you,gracias
    """
    
    let words = try VocabularyCsvParser.parse(csvString: csv)
    
    #expect(words.count == 3)
    #expect(words[0].source == "hello")
    #expect(words[0].translated == "hola")
    #expect(words[1].source == "goodbye")
    #expect(words[1].translated == "adiós")
    #expect(words[2].source == "thank you")
    #expect(words[2].translated == "gracias")
  }
  
  @Test func parseCSVWithHeader() throws {
    let csv = """
    source,translated
    hello,hola
    goodbye,adiós
    """
    
    let words = try VocabularyCsvParser.parse(csvString: csv)
    
    #expect(words.count == 2)
    #expect(words[0].source == "hello")
    #expect(words[0].translated == "hola")
    #expect(words[1].source == "goodbye")
    #expect(words[1].translated == "adiós")
  }
  
  @Test func parseCSVWithCapitalizedHeader() throws {
    let csv = """
    Source,Translated
    cat,gato
    dog,perro
    """
    
    let words = try VocabularyCsvParser.parse(csvString: csv)
    
    #expect(words.count == 2)
    #expect(words[0].source == "cat")
    #expect(words[0].translated == "gato")
    #expect(words[1].source == "dog")
    #expect(words[1].translated == "perro")
  }
  
  // MARK: - Whitespace Handling Tests
  
  @Test func parseCSVWithWhitespace() throws {
    let csv = """
      hello  ,  hola  
    goodbye,adiós
      thank you  ,  gracias
    """
    
    let words = try VocabularyCsvParser.parse(csvString: csv)
    
    #expect(words.count == 3)
    #expect(words[0].source == "hello")
    #expect(words[0].translated == "hola")
    #expect(words[1].source == "goodbye")
    #expect(words[1].translated == "adiós")
  }
  
  @Test func parseCSVWithEmptyLines() throws {
    let csv = """
    hello,hola
    
    goodbye,adiós
    
    
    thank you,gracias
    """
    
    let words = try VocabularyCsvParser.parse(csvString: csv)
    
    #expect(words.count == 3)
    #expect(words[0].source == "hello")
    #expect(words[2].source == "thank you")
  }
  
  // MARK: - Quoted Fields Tests
  
  @Test func parseCSVWithQuotedFields() throws {
    let csv = """
    "hello, hi",hola
    "goodbye, bye","adiós, chao"
    """
    
    let words = try VocabularyCsvParser.parse(csvString: csv)
    
    #expect(words.count == 2)
    #expect(words[0].source == "hello, hi")
    #expect(words[0].translated == "hola")
    #expect(words[1].source == "goodbye, bye")
    #expect(words[1].translated == "adiós, chao")
  }
  
  @Test func parseCSVWithMixedQuoting() throws {
    let csv = """
    hello,"hola, buenos días"
    "good morning",buenos días
    """
    
    let words = try VocabularyCsvParser.parse(csvString: csv)
    
    #expect(words.count == 2)
    #expect(words[0].source == "hello")
    #expect(words[0].translated == "hola, buenos días")
    #expect(words[1].source == "good morning")
    #expect(words[1].translated == "buenos días")
  }
  
  // MARK: - Empty and Edge Cases Tests
  
  @Test func parseEmptyCSV() throws {
    let csv = ""
    
    let words = try VocabularyCsvParser.parse(csvString: csv)
    
    #expect(words.isEmpty)
  }
  
  @Test func parseCSVWithOnlyWhitespace() throws {
    let csv = """
    
    
    
    """
    
    let words = try VocabularyCsvParser.parse(csvString: csv)
    
    #expect(words.isEmpty)
  }
  
  @Test func parseCSVWithOnlyHeader() throws {
    let csv = "source,translated"
    
    let words = try VocabularyCsvParser.parse(csvString: csv)
    
    #expect(words.isEmpty)
  }
  
  @Test func parseSingleEntry() throws {
    let csv = "hello,hola"
    
    let words = try VocabularyCsvParser.parse(csvString: csv)
    
    #expect(words.count == 1)
    #expect(words[0].source == "hello")
    #expect(words[0].translated == "hola")
  }
  
  @Test func parseWithEmptyFields() throws {
    let csv = """
    hello,hola
    incomplete,
    ,adiós
    """
    
    let words = try VocabularyCsvParser.parse(csvString: csv)
    
    #expect(words.count == 1)
    #expect(words[0].source == "hello")
    #expect(words[0].translated == "hola")
  }
  
  // MARK: - Error Cases Tests
  
  @Test func throwErrorForMissingFields() throws {
    let csv = """
    hello,hola
    incomplete
    goodbye,adiós
    """
    
    #expect(throws: VocabularyCsvParser.ParseError.missingRequiredFields) {
      try VocabularyCsvParser.parse(csvString: csv)
    }
  }
  
  @Test func throwErrorForSingleColumn() throws {
    let csv = """
    source
    hello
    goodbye
    """
    
    #expect(throws: VocabularyCsvParser.ParseError.missingRequiredFields) {
      try VocabularyCsvParser.parse(csvString: csv)
    }
  }
  
  // MARK: - Special Characters Tests
  
  @Test func parseCSVWithSpecialCharacters() throws {
    let csv = """
    hello!,¡hola!
    "what's up?","¿qué tal?"
    café,café
    """
    
    let words = try VocabularyCsvParser.parse(csvString: csv)
    
    #expect(words.count == 3)
    #expect(words[0].source == "hello!")
    #expect(words[0].translated == "¡hola!")
    #expect(words[1].source == "what's up?")
    #expect(words[1].translated == "¿qué tal?")
    #expect(words[2].source == "café")
    #expect(words[2].translated == "café")
  }
  
  @Test func parseCSVWithEmoji() throws {
    let csv = """
    smile,sonrisa 😊
    heart,corazón ❤️
    """
    
    let words = try VocabularyCsvParser.parse(csvString: csv)
    
    #expect(words.count == 2)
    #expect(words[0].translated == "sonrisa 😊")
    #expect(words[1].translated == "corazón ❤️")
  }
  
  // MARK: - Extra Columns Tests
  
  @Test func parseCSVWithExtraColumns() throws {
    let csv = """
    hello,hola,greeting,extra
    goodbye,adiós,farewell
    """
    
    let words = try VocabularyCsvParser.parse(csvString: csv)
    
    #expect(words.count == 2)
    #expect(words[0].source == "hello")
    #expect(words[0].translated == "hola")
    #expect(words[1].source == "goodbye")
    #expect(words[1].translated == "adiós")
  }
  
  // MARK: - VocabularyWord Tests
  
  @Test func vocabularyWordUniqueIDs() throws {
    let csv = """
    hello,hola
    hello,hola
    """
    
    let words = try VocabularyCsvParser.parse(csvString: csv)
    
    #expect(words.count == 2)
    #expect(words[0].id != words[1].id)
  }
  
}
