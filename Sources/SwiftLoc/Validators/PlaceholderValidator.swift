import Foundation

struct PlaceholderValidator {
    
    private let placeholderPattern = #"%(?:\d+\$)?[-+0 #]*(?:\d+|\*)?(?:\.(?:\d+|\*))?(?:hh?|ll?|[Lzjt])?[@dDiuUxXoOeEfFgGcCsSpan%]"#
    
    func validate(xliffDocument: XLIFFDocument) -> [PlaceholderError] {
        var errors: [PlaceholderError] = []
        
        for file in xliffDocument.files {
            for unit in file.body.transUnits {
                guard let target = unit.target, !target.isEmpty else {
                    continue
                }
                
                let sourceSpecs = extractPlaceholders(from: unit.source)
                let targetSpecs = extractPlaceholders(from: target)
                
                if let error = comparePlaceholders(
                    key: unit.id,
                    source: unit.source,
                    target: target,
                    sourceSpecs: sourceSpecs,
                    targetSpecs: targetSpecs
                ) {
                    errors.append(error)
                }
            }
        }
        
        return errors
    }
    
    func extractPlaceholders(from string: String) -> [FormatSpecifier] {
        guard let regex = try? NSRegularExpression(pattern: placeholderPattern, options: []) else {
            return []
        }
        
        let range = NSRange(string.startIndex..., in: string)
        let matches = regex.matches(in: string, options: [], range: range)
        
        return matches.compactMap { match in
            guard let matchRange = Range(match.range, in: string) else { return nil }
            let specifier = String(string[matchRange])
            return FormatSpecifier(raw: specifier, position: match.range.location)
        }
    }
    
    private func comparePlaceholders(
        key: String,
        source: String,
        target: String,
        sourceSpecs: [FormatSpecifier],
        targetSpecs: [FormatSpecifier]
    ) -> PlaceholderError? {
        if sourceSpecs.count != targetSpecs.count {
            return PlaceholderError(
                key: key,
                source: source,
                target: target,
                error: "Count mismatch: source has \(sourceSpecs.count) placeholder(s), target has \(targetSpecs.count)"
            )
        }
        
        let sourcePositional = sourceSpecs.filter { $0.isPositional }
        let targetPositional = targetSpecs.filter { $0.isPositional }
        
        if !sourcePositional.isEmpty || !targetPositional.isEmpty {
            return validatePositionalPlaceholders(
                key: key,
                source: source,
                target: target,
                sourceSpecs: sourceSpecs,
                targetSpecs: targetSpecs
            )
        }
        
        let sourceTypes = sourceSpecs.map { $0.type }.sorted()
        let targetTypes = targetSpecs.map { $0.type }.sorted()
        
        if sourceTypes != targetTypes {
            let sourceSummary = sourceSpecs.map { $0.raw }.joined(separator: ", ")
            let targetSummary = targetSpecs.map { $0.raw }.joined(separator: ", ")
            return PlaceholderError(
                key: key,
                source: source,
                target: target,
                error: "Type mismatch: source has [\(sourceSummary)], target has [\(targetSummary)]"
            )
        }
        
        return nil
    }
    
    private func validatePositionalPlaceholders(
        key: String,
        source: String,
        target: String,
        sourceSpecs: [FormatSpecifier],
        targetSpecs: [FormatSpecifier]
    ) -> PlaceholderError? {
        var sourcePositionTypes: [Int: String] = [:]
        var targetPositionTypes: [Int: String] = [:]
        
        for (index, spec) in sourceSpecs.enumerated() {
            let position = spec.positionalIndex ?? (index + 1)
            sourcePositionTypes[position] = spec.type
        }
        
        for (index, spec) in targetSpecs.enumerated() {
            let position = spec.positionalIndex ?? (index + 1)
            targetPositionTypes[position] = spec.type
        }
        
        for (position, sourceType) in sourcePositionTypes {
            guard let targetType = targetPositionTypes[position] else {
                return PlaceholderError(
                    key: key,
                    source: source,
                    target: target,
                    error: "Missing positional placeholder %\(position)$ in target"
                )
            }
            
            if sourceType != targetType {
                return PlaceholderError(
                    key: key,
                    source: source,
                    target: target,
                    error: "Type mismatch at position \(position): source is \(sourceType), target is \(targetType)"
                )
            }
        }
        
        return nil
    }
}

struct FormatSpecifier {
    let raw: String
    let position: Int
    
    var type: String {
        guard let lastChar = raw.last else { return "unknown" }
        return String(lastChar)
    }
    
    var isPositional: Bool {
        raw.contains("$")
    }
    
    var positionalIndex: Int? {
        guard isPositional else { return nil }
        let pattern = #"(\d+)\$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: raw, options: [], range: NSRange(raw.startIndex..., in: raw)),
              let indexRange = Range(match.range(at: 1), in: raw) else {
            return nil
        }
        return Int(raw[indexRange])
    }
}

