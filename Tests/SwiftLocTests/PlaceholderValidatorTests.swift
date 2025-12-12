import XCTest
@testable import SwiftLoc

final class PlaceholderValidatorTests: XCTestCase {
    
    var validator: PlaceholderValidator!
    
    override func setUp() {
        super.setUp()
        validator = PlaceholderValidator()
    }
    
    func testExtractSimplePlaceholder() {
        let specs = validator.extractPlaceholders(from: "Hello, %@!")
        
        XCTAssertEqual(specs.count, 1)
        XCTAssertEqual(specs[0].type, "@")
    }
    
    func testExtractMultiplePlaceholders() {
        let specs = validator.extractPlaceholders(from: "User %@ has %d items")
        
        XCTAssertEqual(specs.count, 2)
        XCTAssertEqual(specs[0].type, "@")
        XCTAssertEqual(specs[1].type, "d")
    }
    
    func testExtractPositionalPlaceholders() {
        let specs = validator.extractPlaceholders(from: "%2$@ and %1$d")
        
        XCTAssertEqual(specs.count, 2)
        XCTAssertTrue(specs[0].isPositional)
        XCTAssertTrue(specs[1].isPositional)
    }
    
    func testValidMatchingPlaceholders() {
        let document = XLIFFDocument(files: [
            XLIFFFile(
                original: "test",
                sourceLanguage: "en",
                targetLanguage: "fr",
                body: XLIFFBody(transUnits: [
                    TransUnit(
                        id: "greeting",
                        source: "Hello, %@!",
                        target: "Bonjour, %@!"
                    )
                ])
            )
        ])
        
        let errors = validator.validate(xliffDocument: document)
        
        XCTAssertTrue(errors.isEmpty)
    }
    
    func testMismatchedPlaceholderTypes() {
        let document = XLIFFDocument(files: [
            XLIFFFile(
                original: "test",
                sourceLanguage: "en",
                targetLanguage: "fr",
                body: XLIFFBody(transUnits: [
                    TransUnit(
                        id: "count",
                        source: "You have %d items",
                        target: "Vous avez %@ articles"
                    )
                ])
            )
        ])
        
        let errors = validator.validate(xliffDocument: document)
        
        XCTAssertEqual(errors.count, 1)
        XCTAssertTrue(errors[0].error.contains("mismatch"))
    }
    
    func testMismatchedPlaceholderCount() {
        let document = XLIFFDocument(files: [
            XLIFFFile(
                original: "test",
                sourceLanguage: "en",
                targetLanguage: "fr",
                body: XLIFFBody(transUnits: [
                    TransUnit(
                        id: "info",
                        source: "%@ has %d items",
                        target: "A %d articles"
                    )
                ])
            )
        ])
        
        let errors = validator.validate(xliffDocument: document)
        
        XCTAssertEqual(errors.count, 1)
        XCTAssertTrue(errors[0].error.contains("Count mismatch"))
    }
    
    func testSkipsUntranslatedStrings() {
        let document = XLIFFDocument(files: [
            XLIFFFile(
                original: "test",
                sourceLanguage: "en",
                targetLanguage: "fr",
                body: XLIFFBody(transUnits: [
                    TransUnit(
                        id: "untranslated",
                        source: "Hello, %@!",
                        target: nil
                    )
                ])
            )
        ])
        
        let errors = validator.validate(xliffDocument: document)
        
        XCTAssertTrue(errors.isEmpty)
    }
    
    func testEscapedPercentSign() {
        let specs = validator.extractPlaceholders(from: "100%% complete with %d items")
        
        XCTAssertEqual(specs.count, 2)
    }
}

