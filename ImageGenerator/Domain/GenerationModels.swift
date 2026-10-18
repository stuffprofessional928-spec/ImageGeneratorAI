import Foundation

struct ImageDimensions: Equatable {
    let width: Int
    let height: Int

    var label: String { "\(width) × \(height)" }
}

struct GenerateRequest: Encodable, Equatable {
    let prompt: String
    let model: GenerationModel
    let resolution: ImageResolution
    let aspectRatio: ImageAspectRatio
    let width: Int
    let height: Int
    let quality: ImageQuality
    let format: ImageFormat
    let referenceImageBase64: String?
}

struct GeneratedImage: Equatable {
    let data: Data
    let format: ImageFormat
    let width: Int
    let height: Int
    let model: String
}

enum GenerateImageError: LocalizedError, Equatable {
    case emptyPrompt
    case server(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .emptyPrompt:
            "Enter a prompt before generating."
        case .server(let message):
            message
        case .invalidResponse:
            "The server returned an invalid image."
        }
    }
}
