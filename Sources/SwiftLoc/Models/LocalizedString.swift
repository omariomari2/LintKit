import Foundation

struct LocalizedString: Hashable, Codable {
    let key: String
    let value: String
    let comment: String
    let tableName: String?
    let sourceFile: String
    let lineNumber: Int
    
    init(
        key: String,
        value: String,
        comment: String = "",
        tableName: String? = nil,
        sourceFile: String = "",
        lineNumber: Int = 0
    ) {
        self.key = key
        self.value = value
        self.comment = comment
        self.tableName = tableName
        self.sourceFile = sourceFile
        self.lineNumber = lineNumber
    }
}

struct ExtractionResult: Codable {
    let strings: [LocalizedString]
    let sourceFiles: [String]
    let extractedAt: Date
    
    var uniqueKeys: Set<String> {
        Set(strings.map { $0.key })
    }
}

struct ValidationError: Codable {
    let key: String
    let errorType: ErrorType
    let message: String
    let sourceFile: String?
    let lineNumber: Int?
    
    enum ErrorType: String, Codable {
        case missingKey
        case placeholderMismatch
        case duplicateKey
    }
}

struct ValidationReport: Codable {
    let missingKeys: [MissingKeyError]
    let placeholderErrors: [PlaceholderError]
    let validatedAt: Date
    let sourceLanguage: String
    let targetLanguage: String
    
    var hasErrors: Bool {
        !missingKeys.isEmpty || !placeholderErrors.isEmpty
    }
    
    var totalErrors: Int {
        missingKeys.count + placeholderErrors.count
    }
}

struct MissingKeyError: Codable {
    let key: String
    let file: String
    let line: Int
}

struct PlaceholderError: Codable {
    let key: String
    let source: String
    let target: String
    let error: String
}

