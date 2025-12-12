import Foundation

struct QualityValidator {
    let client: OllamaClient
    let promptBuilder: PromptBuilder
    let model: String
    
    init(model: String = "llama3.2", client: OllamaClient = OllamaClient()) {
        self.model = model
        self.client = client
        self.promptBuilder = PromptBuilder()
    }
    
    func validate(xliffDocument: XLIFFDocument) async throws -> QualityReport {
        guard await client.isAvailable() else {
            throw QualityValidatorError.ollamaNotRunning
        }
        
        var results: [QualityResult] = []
        
        for file in xliffDocument.files {
            let sourceLanguage = file.sourceLanguage
            let targetLanguage = file.targetLanguage
            
            for unit in file.body.transUnits {
                guard let target = unit.target, !target.isEmpty else {
                    continue
                }
                
                let result = try await validateSingle(
                    key: unit.id,
                    source: unit.source,
                    target: target,
                    sourceLanguage: sourceLanguage,
                    targetLanguage: targetLanguage
                )
                results.append(result)
            }
        }
        
        return QualityReport(results: results, model: model)
    }
    
    func validateSingle(
        key: String,
        source: String,
        target: String,
        sourceLanguage: String,
        targetLanguage: String
    ) async throws -> QualityResult {
        let prompt = promptBuilder.buildQualityPrompt(
            source: source,
            target: target,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            key: key
        )
        
        let response = try await client.generate(prompt: prompt, model: model)
        let parsed = try parseResponse(response)
        
        return QualityResult(
            key: key,
            source: source,
            target: target,
            scores: parsed.toScores(),
            issues: parsed.issues
        )
    }
    
    func validateBatch(
        translations: [(key: String, source: String, target: String)],
        sourceLanguage: String,
        targetLanguage: String
    ) async throws -> [QualityResult] {
        let prompt = promptBuilder.buildBatchQualityPrompt(
            translations: translations,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        )
        
        let response = try await client.generate(prompt: prompt, model: model)
        let parsed = try parseBatchResponse(response, translations: translations)
        
        return parsed
    }
    
    private func parseResponse(_ response: String) throws -> LLMQualityResponse {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var jsonString = trimmed
        if let startIndex = trimmed.firstIndex(of: "{"),
           let endIndex = trimmed.lastIndex(of: "}") {
            jsonString = String(trimmed[startIndex...endIndex])
        }
        
        guard let data = jsonString.data(using: .utf8) else {
            throw QualityValidatorError.invalidResponse
        }
        
        do {
            return try JSONDecoder().decode(LLMQualityResponse.self, from: data)
        } catch {
            throw QualityValidatorError.parsingFailed(response)
        }
    }
    
    private func parseBatchResponse(
        _ response: String,
        translations: [(key: String, source: String, target: String)]
    ) throws -> [QualityResult] {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var jsonString = trimmed
        if let startIndex = trimmed.firstIndex(of: "["),
           let endIndex = trimmed.lastIndex(of: "]") {
            jsonString = String(trimmed[startIndex...endIndex])
        }
        
        guard let data = jsonString.data(using: .utf8) else {
            throw QualityValidatorError.invalidResponse
        }
        
        let responses = try JSONDecoder().decode([LLMQualityResponse].self, from: data)
        
        var results: [QualityResult] = []
        for (index, parsed) in responses.enumerated() {
            let key = parsed.key ?? (index < translations.count ? translations[index].key : "unknown")
            let source = index < translations.count ? translations[index].source : ""
            let target = index < translations.count ? translations[index].target : ""
            
            results.append(QualityResult(
                key: key,
                source: source,
                target: target,
                scores: parsed.toScores(),
                issues: parsed.issues
            ))
        }
        
        return results
    }
}

enum QualityValidatorError: Error, LocalizedError {
    case ollamaNotRunning
    case invalidResponse
    case parsingFailed(String)
    case modelNotAvailable(String)
    
    var errorDescription: String? {
        switch self {
        case .ollamaNotRunning:
            return "Ollama is not running. Start it with 'ollama serve' or ensure it's running on localhost:11434"
        case .invalidResponse:
            return "Received invalid response from LLM"
        case .parsingFailed(let response):
            return "Failed to parse LLM response as JSON. Raw response: \(response.prefix(200))..."
        case .modelNotAvailable(let model):
            return "Model '\(model)' is not available. Run 'ollama pull \(model)' first"
        }
    }
}

