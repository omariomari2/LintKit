import Foundation

struct OllamaClient {
    let baseURL: URL
    let timeout: TimeInterval
    
    init(baseURL: URL = URL(string: "http://localhost:11434")!, timeout: TimeInterval = 60) {
        self.baseURL = baseURL
        self.timeout = timeout
    }
    
    func generate(prompt: String, model: String) async throws -> String {
        let endpoint = baseURL.appendingPathComponent("api/generate")
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeout
        
        let requestBody = OllamaRequest(model: model, prompt: prompt, stream: false)
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OllamaError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw OllamaError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let ollamaResponse = try JSONDecoder().decode(OllamaResponse.self, from: data)
        return ollamaResponse.response
    }
    
    func isAvailable() async -> Bool {
        let endpoint = baseURL.appendingPathComponent("api/tags")
        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 5
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return false }
            return httpResponse.statusCode == 200
        } catch {
            return false
        }
    }
    
    func listModels() async throws -> [String] {
        let endpoint = baseURL.appendingPathComponent("api/tags")
        
        let (data, response) = try await URLSession.shared.data(from: endpoint)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw OllamaError.invalidResponse
        }
        
        let tagsResponse = try JSONDecoder().decode(OllamaTagsResponse.self, from: data)
        return tagsResponse.models.map { $0.name }
    }
}

struct OllamaRequest: Encodable {
    let model: String
    let prompt: String
    let stream: Bool
}

struct OllamaResponse: Decodable {
    let response: String
    let done: Bool
}

struct OllamaTagsResponse: Decodable {
    let models: [OllamaModel]
}

struct OllamaModel: Decodable {
    let name: String
}

enum OllamaError: Error, LocalizedError {
    case connectionFailed
    case invalidResponse
    case httpError(statusCode: Int)
    case modelNotFound(String)
    case parsingFailed
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Failed to connect to Ollama. Ensure Ollama is running on localhost:11434"
        case .invalidResponse:
            return "Invalid response from Ollama API"
        case .httpError(let code):
            return "Ollama API returned HTTP \(code)"
        case .modelNotFound(let model):
            return "Model '\(model)' not found. Run 'ollama pull \(model)' first"
        case .parsingFailed:
            return "Failed to parse Ollama response"
        }
    }
}

