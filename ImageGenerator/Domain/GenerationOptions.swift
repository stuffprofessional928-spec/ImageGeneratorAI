import Foundation

enum GenerationModel: String, CaseIterable, Identifiable, Codable {
    case qwenImage = "qwen/qwen-image-2.1-turbo"
    case fluxImage = "black-forest-labs/flux-3-image-klein"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .qwenImage: "Qwen Image 2.1 Turbo"
        case .fluxImage: "FLUX.3 Image Klein"
        }
    }
}

enum ImageResolution: String, CaseIterable, Identifiable, Codable {
    case oneK = "1K"
    case oneFiveK = "1.5K"
    case twoK = "2K"
    case fourK = "4K"

    var id: String { rawValue }

    var baseEdge: Int {
        switch self {
        case .oneK: 1024
        case .twoK: 2048
        case .oneFiveK: 1536
        case .fourK: 4096
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
