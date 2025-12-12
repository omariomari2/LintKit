import Foundation

struct QualityReport: Codable {
    let qualityResults: [QualityResult]
    let averageScore: Double
    let flaggedTranslations: Int
    let analyzedAt: Date
    let model: String
    
    init(results: [QualityResult], model: String) {
        self.qualityResults = results
        self.model = model
        self.analyzedAt = Date()
        
        let allScores = results.flatMap { [$0.scores.meaning, $0.scores.tone, $0.scores.completeness] }
        self.averageScore = allScores.isEmpty ? 0 : Double(allScores.reduce(0, +)) / Double(allScores.count)
        self.flaggedTranslations = results.filter { !$0.issues.isEmpty || $0.scores.minimum < 4 }.count
    }
}

struct QualityResult: Codable {
    let key: String
    let source: String
    let target: String
    let scores: QualityScores
    let issues: [String]
    
    var isPassing: Bool {
        scores.minimum >= 4 && issues.isEmpty
    }
}

struct QualityScores: Codable {
    let meaning: Int
    let tone: Int
    let completeness: Int
    
    var average: Double {
        Double(meaning + tone + completeness) / 3.0
    }
    
    var minimum: Int {
        min(meaning, min(tone, completeness))
    }
}

struct LLMQualityResponse: Decodable {
    let meaning: Int
    let tone: Int
    let completeness: Int
    let issues: [String]
    var key: String?
    
    func toScores() -> QualityScores {
        QualityScores(meaning: meaning, tone: tone, completeness: completeness)
    }
}

