import Foundation
import XMLCoder

struct XLIFFGenerator {
    
    private let encoder: XMLEncoder
    private let decoder: XMLDecoder
    
    init() {
        encoder = XMLEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        
        decoder = XMLDecoder()
    }
    
    func generate(
        from strings: [LocalizedString],
        sourceLanguage: String,
        targetLanguage: String,
        originalFile: String = "Localizable.strings"
    ) -> XLIFFDocument {
        let transUnits = strings.map { string in
            TransUnit(
                id: string.key,
                source: string.value,
                target: nil,
                note: string.comment.isEmpty ? nil : string.comment
            )
        }
        
        let body = XLIFFBody(transUnits: transUnits)
        let file = XLIFFFile(
            original: originalFile,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            body: body
        )
        
        return XLIFFDocument(files: [file])
    }
    
    func merge(
        existing: XLIFFDocument,
        with newStrings: [LocalizedString]
    ) -> XLIFFDocument {
        var updatedDocument = existing
        
        for (fileIndex, file) in existing.files.enumerated() {
            var existingKeys = Set(file.body.transUnits.map { $0.id })
            var updatedTransUnits = file.body.transUnits
            
            for string in newStrings {
                if !existingKeys.contains(string.key) {
                    let newUnit = TransUnit(
                        id: string.key,
                        source: string.value,
                        target: nil,
                        note: string.comment.isEmpty ? nil : string.comment
                    )
                    updatedTransUnits.append(newUnit)
                    existingKeys.insert(string.key)
                }
            }
            
            updatedDocument.files[fileIndex].body.transUnits = updatedTransUnits
        }
        
        return updatedDocument
    }
    
    func write(_ document: XLIFFDocument, to path: String) throws {
        let xmlHeader = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        let data = try encoder.encode(document, withRootKey: "xliff")
        
        guard var xmlString = String(data: data, encoding: .utf8) else {
            throw GeneratorError.encodingFailed
        }
        
        xmlString = xmlHeader + xmlString
        
        try xmlString.write(toFile: path, atomically: true, encoding: .utf8)
    }
    
    func read(from path: String) throws -> XLIFFDocument {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try decoder.decode(XLIFFDocument.self, from: data)
    }
    
    func updateOrCreate(
        at path: String,
        with strings: [LocalizedString],
        sourceLanguage: String,
        targetLanguage: String
    ) throws {
        let fileManager = FileManager.default
        
        let document: XLIFFDocument
        if fileManager.fileExists(atPath: path) {
            let existing = try read(from: path)
            document = merge(existing: existing, with: strings)
        } else {
            document = generate(
                from: strings,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage
            )
        }
        
        try write(document, to: path)
    }
}

enum GeneratorError: Error, LocalizedError {
    case encodingFailed
    case decodingFailed
    case fileWriteFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode XLIFF document"
        case .decodingFailed:
            return "Failed to decode XLIFF document"
        case .fileWriteFailed(let path):
            return "Failed to write file: \(path)"
        }
    }
}

