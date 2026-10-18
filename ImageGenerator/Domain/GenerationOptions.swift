import Foundation

enum GenerationModel: String, CaseIterable, Identifiable, Codable {
    case gpt4o = "GPT-4o"
    case claude = "Claude"
    case gemini = "Gemini"
    case llama = "Llama"

    var id: String { rawValue }
}

enum ImageResolution: String, CaseIterable, Identifiable, Codable {
    case oneK = "1K"
    case twoK = "2K"

    var id: String { rawValue }

    var baseEdge: Int {
        switch self {
        case .oneK: 1024
        case .twoK: 2048
        }
    }
}

enum ImageAspectRatio: String, CaseIterable, Identifiable, Codable {
    case square = "1:1"
    case portrait = "4:5"
    case landscape = "3:2"
    case widescreen = "16:9"
    case tall = "9:16"

    var id: String { rawValue }

    var value: (width: Int, height: Int) {
        switch self {
        case .square: (1, 1)
        case .portrait: (4, 5)
        case .landscape: (3, 2)
        case .widescreen: (16, 9)
        case .tall: (9, 16)
        }
    }
}

enum ImageQuality: String, CaseIterable, Identifiable, Codable {
    case standard = "Standard"
    case high = "High"

    var id: String { rawValue }
}

enum ImageFormat: String, CaseIterable, Identifiable, Codable {
    case png = "PNG"
    case jpeg = "JPEG"
    case webp = "WEBP"

    var id: String { rawValue }

    var fileExtension: String {
        switch self {
        case .png: "png"
        case .jpeg: "jpg"
        case .webp: "webp"
        }
    }
}
