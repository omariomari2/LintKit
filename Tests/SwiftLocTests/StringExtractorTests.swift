import XCTest
@testable import SwiftLoc

final class StringExtractorTests: XCTestCase {
    
    var extractor: StringExtractor!
    
    override func setUp() {
        super.setUp()
        extractor = StringExtractor()
    }
    
    func testExtractNSLocalizedString() {
        let code = """
        let greeting = NSLocalizedString("hello_world", comment: "Greeting message")
        """
        
        let results = extractor.extractFromContent(code)
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].key, "hello_world")
        XCTAssertEqual(results[0].comment, "Greeting message")
    }
    
    func testExtractNSLocalizedStringWithTableName() {
        let code = """
        let msg = NSLocalizedString("error_message", tableName: "Errors", comment: "Error display")
        """
        
        let results = extractor.extractFromContent(code)
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].key, "error_message")
        XCTAssertEqual(results[0].tableName, "Errors")
    }
    
    func testExtractStringLocalized() {
        let code = """
        let label = String(localized: "button_title")
        """
        
        let results = extractor.extractFromContent(code)
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].key, "button_title")
    }
    
    func testExtractStringLocalizedWithComment() {
        let code = """
        let text = String(localized: "welcome_text", comment: "Welcome screen title")
        """
        
        let results = extractor.extractFromContent(code)
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].key, "welcome_text")
        XCTAssertEqual(results[0].comment, "Welcome screen title")
    }
    
    func testExtractMultipleStrings() {
        let code = """
        let a = NSLocalizedString("key_one", comment: "First")
        let b = NSLocalizedString("key_two", comment: "Second")
        let c = String(localized: "key_three")
        """
        
        let results = extractor.extractFromContent(code)
        
        XCTAssertEqual(results.count, 3)
        XCTAssertTrue(results.contains { $0.key == "key_one" })
        XCTAssertTrue(results.contains { $0.key == "key_two" })
        XCTAssertTrue(results.contains { $0.key == "key_three" })
    }
    
    func testExtractFromEmptyContent() {
        let code = """
        let x = 42
        print("Hello")
        """
        
        let results = extractor.extractFromContent(code)
        
        XCTAssertEqual(results.count, 0)
    }
    
    func testLineNumberTracking() {
        let code = """
        let a = 1
        let b = 2
        let c = NSLocalizedString("on_line_three", comment: "Test")
        let d = 4
        """
        
        let results = extractor.extractFromContent(code)
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].lineNumber, 3)
    }
}

