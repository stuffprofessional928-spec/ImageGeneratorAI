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
    let image: String

    private enum CodingKeys: String, CodingKey {
        case prompt
        case model
        case resolution
        case aspectRatio = "aspect_ratio"
        case dimensions
        case image
        case quality
        case format = "output"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(prompt, forKey: .prompt)
        try container.encode(model.rawValue, forKey: .model)
        try container.encode(resolution.rawValue, forKey: .resolution)
        try container.encode(aspectRatio.rawValue, forKey: .aspectRatio)
        try container.encode("\(width)x\(height)", forKey: .dimensions)
        try container.encode(image, forKey: .image)
        try container.encode(quality.rawValue.lowercased(), forKey: .quality)
        try container.encode(format.rawValue.lowercased(), forKey: .format)
    }
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
