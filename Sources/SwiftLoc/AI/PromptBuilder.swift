import Foundation

struct PromptBuilder {
    
    func buildQualityPrompt(
        source: String,
        target: String,
        sourceLanguage: String,
        targetLanguage: String,
        key: String
    ) -> String {
        return """
        You are a localization quality reviewer. Analyze this translation pair:

        Key: "\(key)"
        Source (\(languageName(for: sourceLanguage))): "\(source)"
        Target (\(languageName(for: targetLanguage))): "\(target)"

        Evaluate the translation on these criteria (score 1-5, where 5 is perfect):

        1. MEANING: Does the translation convey the exact same information as the source?
        2. TONE: Is the formality/casualness level preserved appropriately?
        3. COMPLETENESS: Is any information missing or incorrectly added?

        Respond ONLY with valid JSON in this exact format:
        {"meaning": <score>, "tone": <score>, "completeness": <score>, "issues": ["issue1", "issue2"]}

        If there are no issues, use an empty array: "issues": []
        Do not include any text outside the JSON object.
        """
    }
    
    func buildBatchQualityPrompt(
        translations: [(key: String, source: String, target: String)],
        sourceLanguage: String,
        targetLanguage: String
    ) -> String {
        var translationList = ""
        for (index, t) in translations.enumerated() {
            translationList += """
            
            \(index + 1). Key: "\(t.key)"
               Source: "\(t.source)"
               Target: "\(t.target)"
            """
        }
        
        return """
        You are a localization quality reviewer. Analyze these \(sourceLanguage) to \(targetLanguage) translations:
        \(translationList)

        For each translation, evaluate:
        - MEANING (1-5): Does it convey the same information?
        - TONE (1-5): Is formality preserved?
        - COMPLETENESS (1-5): Is anything missing or added?

        Respond ONLY with a JSON array:
        [
          {"key": "key1", "meaning": 5, "tone": 5, "completeness": 5, "issues": []},
          {"key": "key2", "meaning": 4, "tone": 3, "completeness": 5, "issues": ["Tone is more formal than source"]}
        ]

        Do not include any text outside the JSON array.
        """
    }
    
    private func languageName(for code: String) -> String {
        let mapping: [String: String] = [
            "en": "English",
            "fr": "French",
            "de": "German",
            "es": "Spanish",
            "it": "Italian",
            "pt": "Portuguese",
            "ja": "Japanese",
            "ko": "Korean",
            "zh": "Chinese",
            "ar": "Arabic",
            "ru": "Russian",
            "nl": "Dutch",
            "pl": "Polish",
            "tr": "Turkish",
            "vi": "Vietnamese",
            "th": "Thai",
            "sv": "Swedish",
            "da": "Danish",
            "fi": "Finnish",
            "no": "Norwegian"
        ]
        return mapping[code.lowercased()] ?? code.uppercased()
    }
}

