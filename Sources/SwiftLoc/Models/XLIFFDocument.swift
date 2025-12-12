import Foundation
import XMLCoder

struct XLIFFDocument: Codable {
    var files: [XLIFFFile]
    let version: String
    let xmlns: String
    
    enum CodingKeys: String, CodingKey {
        case files = "file"
        case version
        case xmlns
    }
    
    init(files: [XLIFFFile] = [], version: String = "1.2") {
        self.files = files
        self.version = version
        self.xmlns = "urn:oasis:names:tc:xliff:document:1.2"
    }
}

struct XLIFFFile: Codable {
    var body: XLIFFBody
    let original: String
    let sourceLanguage: String
    let targetLanguage: String
    let datatype: String
    
    enum CodingKeys: String, CodingKey {
        case body
        case original
        case sourceLanguage = "source-language"
        case targetLanguage = "target-language"
        case datatype
    }
    
    init(
        original: String,
        sourceLanguage: String,
        targetLanguage: String,
        body: XLIFFBody = XLIFFBody(),
        datatype: String = "plaintext"
    ) {
        self.original = original
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.body = body
        self.datatype = datatype
    }
}

struct XLIFFBody: Codable {
    var transUnits: [TransUnit]
    
    enum CodingKeys: String, CodingKey {
        case transUnits = "trans-unit"
    }
    
    init(transUnits: [TransUnit] = []) {
        self.transUnits = transUnits
    }
}

struct TransUnit: Codable {
    let id: String
    var source: String
    var target: String?
    var note: String?
    
    init(id: String, source: String, target: String? = nil, note: String? = nil) {
        self.id = id
        self.source = source
        self.target = target
        self.note = note
    }
}

extension XLIFFDocument: DynamicNodeEncoding {
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        switch key {
        case CodingKeys.version, CodingKeys.xmlns:
            return .attribute
        default:
            return .element
        }
    }
}

extension XLIFFFile: DynamicNodeEncoding {
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        switch key {
        case CodingKeys.original, CodingKeys.sourceLanguage, CodingKeys.targetLanguage, CodingKeys.datatype:
            return .attribute
        default:
            return .element
        }
    }
}

extension TransUnit: DynamicNodeEncoding {
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        switch key {
        case CodingKeys.id:
            return .attribute
        default:
            return .element
        }
    }
}

