import Foundation

struct StringExtractor {
    
    private let nsLocalizedStringPattern = #"NSLocalizedString\s*\(\s*"([^"\\]*(?:\\.[^"\\]*)*)"\s*,\s*(?:tableName:\s*"([^"\\]*(?:\\.[^"\\]*)*)"\s*,\s*)?(?:bundle:\s*[^,]+\s*,\s*)?(?:value:\s*"[^"\\]*(?:\\.[^"\\]*)*"\s*,\s*)?comment:\s*"([^"\\]*(?:\\.[^"\\]*)*)"\s*\)"#
    
    private let stringLocalizedPattern = #"String\s*\(\s*localized:\s*"([^"\\]*(?:\\.[^"\\]*)*)"\s*(?:,\s*defaultValue:\s*"([^"\\]*(?:\\.[^"\\]*)*)"\s*)?(?:,\s*table:\s*"([^"\\]*(?:\\.[^"\\]*)*)"\s*)?(?:,\s*bundle:\s*[^,)]+\s*)?(?:,\s*locale:\s*[^,)]+\s*)?(?:,\s*comment:\s*"([^"\\]*(?:\\.[^"\\]*)*)"\s*)?\)"#
    
    private let localizedStringResourcePattern = #"LocalizedStringResource\s*\(\s*"([^"\\]*(?:\\.[^"\\]*)*)"\s*(?:,\s*defaultValue:\s*"([^"\\]*(?:\\.[^"\\]*)*)"\s*)?(?:,\s*table:\s*"([^"\\]*(?:\\.[^"\\]*)*)"\s*)?(?:,\s*locale:\s*[^,)]+\s*)?(?:,\s*bundle:\s*[^,)]+\s*)?(?:,\s*comment:\s*"([^"\\]*(?:\\.[^"\\]*)*)"\s*)?\)"#
    
    func extractFromFile(at path: String) throws -> [LocalizedString] {
        let content = try String(contentsOfFile: path, encoding: .utf8)
        return extractFromContent(content, sourceFile: path)
    }
    
    func extractFromContent(_ content: String, sourceFile: String = "") -> [LocalizedString] {
        var results: [LocalizedString] = []
        let lines = content.components(separatedBy: .newlines)
        
        results.append(contentsOf: extractNSLocalizedStrings(from: content, lines: lines, sourceFile: sourceFile))
        results.append(contentsOf: extractStringLocalized(from: content, lines: lines, sourceFile: sourceFile))
        results.append(contentsOf: extractLocalizedStringResource(from: content, lines: lines, sourceFile: sourceFile))
        
        return results
    }
    
    private func extractNSLocalizedStrings(from content: String, lines: [String], sourceFile: String) -> [LocalizedString] {
        var results: [LocalizedString] = []
        
        guard let regex = try? NSRegularExpression(pattern: nsLocalizedStringPattern, options: [.dotMatchesLineSeparators]) else {
            return results
        }
        
        let range = NSRange(content.startIndex..., in: content)
        let matches = regex.matches(in: content, options: [], range: range)
        
        for match in matches {
            guard let keyRange = Range(match.range(at: 1), in: content) else { continue }
            let key = String(content[keyRange])
            
            var tableName: String? = nil
            if match.range(at: 2).location != NSNotFound,
               let tableRange = Range(match.range(at: 2), in: content) {
                tableName = String(content[tableRange])
            }
            
            var comment = ""
            if match.range(at: 3).location != NSNotFound,
               let commentRange = Range(match.range(at: 3), in: content) {
                comment = String(content[commentRange])
            }
            
            let lineNumber = findLineNumber(for: match.range.location, in: content, lines: lines)
            
            results.append(LocalizedString(
                key: key,
                value: key,
                comment: comment,
                tableName: tableName,
                sourceFile: sourceFile,
                lineNumber: lineNumber
            ))
        }
        
        return results
    }
    
    private func extractStringLocalized(from content: String, lines: [String], sourceFile: String) -> [LocalizedString] {
        var results: [LocalizedString] = []
        
        guard let regex = try? NSRegularExpression(pattern: stringLocalizedPattern, options: [.dotMatchesLineSeparators]) else {
            return results
        }
        
        let range = NSRange(content.startIndex..., in: content)
        let matches = regex.matches(in: content, options: [], range: range)
        
        for match in matches {
            guard let keyRange = Range(match.range(at: 1), in: content) else { continue }
            let key = String(content[keyRange])
            
            var defaultValue = key
            if match.range(at: 2).location != NSNotFound,
               let valueRange = Range(match.range(at: 2), in: content) {
                defaultValue = String(content[valueRange])
            }
            
            var tableName: String? = nil
            if match.range(at: 3).location != NSNotFound,
               let tableRange = Range(match.range(at: 3), in: content) {
                tableName = String(content[tableRange])
            }
            
            var comment = ""
            if match.range(at: 4).location != NSNotFound,
               let commentRange = Range(match.range(at: 4), in: content) {
                comment = String(content[commentRange])
            }
            
            let lineNumber = findLineNumber(for: match.range.location, in: content, lines: lines)
            
            results.append(LocalizedString(
                key: key,
                value: defaultValue,
                comment: comment,
                tableName: tableName,
                sourceFile: sourceFile,
                lineNumber: lineNumber
            ))
        }
        
        return results
    }
    
    private func extractLocalizedStringResource(from content: String, lines: [String], sourceFile: String) -> [LocalizedString] {
        var results: [LocalizedString] = []
        
        guard let regex = try? NSRegularExpression(pattern: localizedStringResourcePattern, options: [.dotMatchesLineSeparators]) else {
            return results
        }
        
        let range = NSRange(content.startIndex..., in: content)
        let matches = regex.matches(in: content, options: [], range: range)
        
        for match in matches {
            guard let keyRange = Range(match.range(at: 1), in: content) else { continue }
            let key = String(content[keyRange])
            
            var defaultValue = key
            if match.range(at: 2).location != NSNotFound,
               let valueRange = Range(match.range(at: 2), in: content) {
                defaultValue = String(content[valueRange])
            }
            
            var tableName: String? = nil
            if match.range(at: 3).location != NSNotFound,
               let tableRange = Range(match.range(at: 3), in: content) {
                tableName = String(content[tableRange])
            }
            
            var comment = ""
            if match.range(at: 4).location != NSNotFound,
               let commentRange = Range(match.range(at: 4), in: content) {
                comment = String(content[commentRange])
            }
            
            let lineNumber = findLineNumber(for: match.range.location, in: content, lines: lines)
            
            results.append(LocalizedString(
                key: key,
                value: defaultValue,
                comment: comment,
                tableName: tableName,
                sourceFile: sourceFile,
                lineNumber: lineNumber
            ))
        }
        
        return results
    }
    
    private func findLineNumber(for location: Int, in content: String, lines: [String]) -> Int {
        var currentLocation = 0
        for (index, line) in lines.enumerated() {
            currentLocation += line.count + 1
            if currentLocation > location {
                return index + 1
            }
        }
        return lines.count
    }
    
    func extractFromDirectory(at path: String) throws -> ExtractionResult {
        let fileManager = FileManager.default
        var allStrings: [LocalizedString] = []
        var sourceFiles: [String] = []
        
        guard let enumerator = fileManager.enumerator(atPath: path) else {
            throw ExtractorError.directoryNotFound(path)
        }
        
        while let file = enumerator.nextObject() as? String {
            if file.hasSuffix(".swift") {
                let fullPath = (path as NSString).appendingPathComponent(file)
                sourceFiles.append(fullPath)
                
                do {
                    let strings = try extractFromFile(at: fullPath)
                    allStrings.append(contentsOf: strings)
                } catch {
                    continue
                }
            }
        }
        
        return ExtractionResult(
            strings: allStrings,
            sourceFiles: sourceFiles,
            extractedAt: Date()
        )
    }
}

enum ExtractorError: Error, LocalizedError {
    case directoryNotFound(String)
    case fileNotFound(String)
    case invalidContent(String)
    
    var errorDescription: String? {
        switch self {
        case .directoryNotFound(let path):
            return "Directory not found: \(path)"
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .invalidContent(let path):
            return "Invalid content in file: \(path)"
        }
    }
}

