import ArgumentParser
import Foundation

@main
struct SwiftLoc: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swiftloc",
        abstract: "Automated localization extraction and validation for Swift projects",
        version: "1.0.0",
        subcommands: [Extract.self, Validate.self, Report.self]
    )
}

struct Extract: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Extract localized strings from Swift source files"
    )
    
    @Option(name: .shortAndLong, help: "Path to source directory or file")
    var source: String
    
    @Option(name: .shortAndLong, help: "Output XLIFF file path")
    var output: String
    
    @Option(name: .long, help: "Source language code (e.g., en)")
    var sourceLanguage: String = "en"
    
    @Option(name: .long, help: "Target language code (e.g., fr)")
    var targetLanguage: String = "fr"
    
    @Flag(name: .long, help: "Merge with existing XLIFF file instead of overwriting")
    var merge: Bool = false
    
    @Flag(name: .long, help: "Output extraction results as JSON")
    var json: Bool = false
    
    func run() throws {
        let extractor = StringExtractor()
        let generator = XLIFFGenerator()
        
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        
        guard fileManager.fileExists(atPath: source, isDirectory: &isDirectory) else {
            throw ExitCode.failure
        }
        
        let result: ExtractionResult
        if isDirectory.boolValue {
            result = try extractor.extractFromDirectory(at: source)
        } else {
            let strings = try extractor.extractFromFile(at: source)
            result = ExtractionResult(strings: strings, sourceFiles: [source], extractedAt: Date())
        }
        
        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(result)
            if let jsonString = String(data: data, encoding: .utf8) {
                print(jsonString)
            }
        } else {
            print("Extracted \(result.strings.count) string(s) from \(result.sourceFiles.count) file(s)")
            
            for string in result.strings {
                print("  - \(string.key): \"\(string.value)\"")
            }
        }
        
        if merge && fileManager.fileExists(atPath: output) {
            try generator.updateOrCreate(
                at: output,
                with: result.strings,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage
            )
            print("\nMerged into existing XLIFF: \(output)")
        } else {
            let document = generator.generate(
                from: result.strings,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage
            )
            try generator.write(document, to: output)
            print("\nGenerated XLIFF: \(output)")
        }
    }
}

struct Validate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Validate XLIFF files against source code"
    )
    
    @Option(name: .shortAndLong, help: "Path to XLIFF file")
    var xliff: String
    
    @Option(name: .shortAndLong, help: "Path to source directory or file")
    var source: String?
    
    @Flag(name: .long, help: "Check for placeholder mismatches")
    var placeholders: Bool = false
    
    @Flag(name: .long, help: "Check for missing keys in XLIFF")
    var missingKeys: Bool = false
    
    @Flag(name: .long, help: "Run AI-powered quality checks using Ollama")
    var quality: Bool = false
    
    @Option(name: .long, help: "Ollama model to use for quality checks")
    var model: String = "llama3.2"
    
    @Flag(name: .long, help: "Run all validation checks (excludes AI quality)")
    var all: Bool = false
    
    @Flag(name: .long, help: "Output validation results as JSON")
    var json: Bool = false
    
    func run() async throws {
        let generator = XLIFFGenerator()
        let document = try generator.read(from: xliff)
        
        var missingKeyErrors: [MissingKeyError] = []
        var placeholderErrors: [PlaceholderError] = []
        var qualityReport: QualityReport? = nil
        
        if all || missingKeys {
            if let sourcePath = source {
                let extractor = StringExtractor()
                let fileManager = FileManager.default
                var isDirectory: ObjCBool = false
                
                guard fileManager.fileExists(atPath: sourcePath, isDirectory: &isDirectory) else {
                    print("Source path not found: \(sourcePath)")
                    throw ExitCode.failure
                }
                
                let result: ExtractionResult
                if isDirectory.boolValue {
                    result = try extractor.extractFromDirectory(at: sourcePath)
                } else {
                    let strings = try extractor.extractFromFile(at: sourcePath)
                    result = ExtractionResult(strings: strings, sourceFiles: [sourcePath], extractedAt: Date())
                }
                
                let validator = MissingKeyValidator()
                missingKeyErrors = validator.validate(extractedStrings: result.strings, xliffDocument: document)
            } else {
                print("Warning: --source required for missing key validation")
            }
        }
        
        if all || placeholders {
            let validator = PlaceholderValidator()
            placeholderErrors = validator.validate(xliffDocument: document)
        }
        
        if quality {
            print("Running AI quality analysis with model: \(model)...")
            let qualityValidator = QualityValidator(model: model)
            qualityReport = try await qualityValidator.validate(xliffDocument: document)
        }
        
        let sourceLanguage = document.files.first?.sourceLanguage ?? "unknown"
        let targetLanguage = document.files.first?.targetLanguage ?? "unknown"
        
        let report = ValidationReport(
            missingKeys: missingKeyErrors,
            placeholderErrors: placeholderErrors,
            validatedAt: Date(),
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        )
        
        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            
            if let qr = qualityReport {
                let combined = CombinedReport(validation: report, quality: qr)
                let data = try encoder.encode(combined)
                if let jsonString = String(data: data, encoding: .utf8) {
                    print(jsonString)
                }
            } else {
                let data = try encoder.encode(report)
                if let jsonString = String(data: data, encoding: .utf8) {
                    print(jsonString)
                }
            }
        } else {
            printReport(report)
            if let qr = qualityReport {
                printQualityReport(qr)
            }
        }
        
        let hasQualityIssues = qualityReport?.flaggedTranslations ?? 0 > 0
        if report.hasErrors || hasQualityIssues {
            throw ExitCode(1)
        }
    }
    
    private func printReport(_ report: ValidationReport) {
        print("Validation Report")
        print("=================")
        print("Source Language: \(report.sourceLanguage)")
        print("Target Language: \(report.targetLanguage)")
        print("")
        
        if !report.missingKeys.isEmpty {
            print("Missing Keys (\(report.missingKeys.count)):")
            for error in report.missingKeys {
                print("  - \(error.key) (\(error.file):\(error.line))")
            }
            print("")
        }
        
        if !report.placeholderErrors.isEmpty {
            print("Placeholder Errors (\(report.placeholderErrors.count)):")
            for error in report.placeholderErrors {
                print("  - \(error.key): \(error.error)")
                print("    Source: \"\(error.source)\"")
                print("    Target: \"\(error.target)\"")
            }
            print("")
        }
        
        if report.hasErrors {
            print("Total Errors: \(report.totalErrors)")
        } else {
            print("No validation errors found.")
        }
    }
    
    private func printQualityReport(_ report: QualityReport) {
        print("")
        print("AI Quality Analysis")
        print("===================")
        print("Model: \(report.model)")
        print("Average Score: \(String(format: "%.1f", report.averageScore))/5.0")
        print("Flagged Translations: \(report.flaggedTranslations)")
        print("")
        
        let flagged = report.qualityResults.filter { !$0.isPassing }
        if !flagged.isEmpty {
            print("Quality Issues:")
            for result in flagged {
                print("  - \(result.key)")
                print("    Scores: meaning=\(result.scores.meaning) tone=\(result.scores.tone) completeness=\(result.scores.completeness)")
                if !result.issues.isEmpty {
                    for issue in result.issues {
                        print("    Issue: \(issue)")
                    }
                }
            }
        } else {
            print("All translations passed quality checks.")
        }
    }
}

struct CombinedReport: Codable {
    let validation: ValidationReport
    let quality: QualityReport
}

struct Report: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Generate reports from extraction and validation"
    )
    
    @Option(name: .shortAndLong, help: "Path to XLIFF file")
    var xliff: String
    
    @Option(name: .shortAndLong, help: "Output format (json, text)")
    var format: String = "text"
    
    @Option(name: .shortAndLong, help: "Output file path (stdout if not specified)")
    var output: String?
    
    func run() throws {
        let generator = XLIFFGenerator()
        let document = try generator.read(from: xliff)
        
        var totalStrings = 0
        var translatedStrings = 0
        var untranslatedStrings = 0
        
        for file in document.files {
            for unit in file.body.transUnits {
                totalStrings += 1
                if let target = unit.target, !target.isEmpty {
                    translatedStrings += 1
                } else {
                    untranslatedStrings += 1
                }
            }
        }
        
        let coverage = totalStrings > 0 ? Double(translatedStrings) / Double(totalStrings) * 100 : 0
        
        let reportContent: String
        if format == "json" {
            let reportData: [String: Any] = [
                "file": xliff,
                "totalStrings": totalStrings,
                "translatedStrings": translatedStrings,
                "untranslatedStrings": untranslatedStrings,
                "coveragePercent": coverage
            ]
            if let jsonData = try? JSONSerialization.data(withJSONObject: reportData, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                reportContent = jsonString
            } else {
                reportContent = "{}"
            }
        } else {
            reportContent = """
            Translation Coverage Report
            ===========================
            File: \(xliff)
            
            Total Strings: \(totalStrings)
            Translated: \(translatedStrings)
            Untranslated: \(untranslatedStrings)
            Coverage: \(String(format: "%.1f", coverage))%
            """
        }
        
        if let outputPath = output {
            try reportContent.write(toFile: outputPath, atomically: true, encoding: .utf8)
            print("Report written to: \(outputPath)")
        } else {
            print(reportContent)
        }
    }
}
