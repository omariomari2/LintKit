import Foundation

struct MissingKeyValidator {
    
    func validate(
        extractedStrings: [LocalizedString],
        xliffDocument: XLIFFDocument
    ) -> [MissingKeyError] {
        var missingKeys: [MissingKeyError] = []
        
        var xliffKeys = Set<String>()
        for file in xliffDocument.files {
            for unit in file.body.transUnits {
                xliffKeys.insert(unit.id)
            }
        }
        
        for string in extractedStrings {
            if !xliffKeys.contains(string.key) {
                missingKeys.append(MissingKeyError(
                    key: string.key,
                    file: string.sourceFile,
                    line: string.lineNumber
                ))
            }
        }
        
        return missingKeys
    }
    
    func findUnusedKeys(
        extractedStrings: [LocalizedString],
        xliffDocument: XLIFFDocument
    ) -> [String] {
        let sourceKeys = Set(extractedStrings.map { $0.key })
        var unusedKeys: [String] = []
        
        for file in xliffDocument.files {
            for unit in file.body.transUnits {
                if !sourceKeys.contains(unit.id) {
                    unusedKeys.append(unit.id)
                }
            }
        }
        
        return unusedKeys
    }
    
    func findDuplicateKeys(in strings: [LocalizedString]) -> [String: [LocalizedString]] {
        var keyOccurrences: [String: [LocalizedString]] = [:]
        
        for string in strings {
            keyOccurrences[string.key, default: []].append(string)
        }
        
        return keyOccurrences.filter { $0.value.count > 1 }
    }
}

