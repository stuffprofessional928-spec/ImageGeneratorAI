import Foundation

final class URLSessionImageAPIClient: ImageAPIClient, @unchecked Sendable {
    private static let requestTimeout: TimeInterval = 300
    private static let resourceTimeout: TimeInterval = 300

    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL = URL(string: "https://chatai-5w9x.onrender.com/")!, session: URLSession? = nil) {
        self.baseURL = baseURL
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = Self.requestTimeout
            configuration.timeoutIntervalForResource = Self.resourceTimeout
            self.session = URLSession(configuration: configuration)
        }
    }

    func generate(_ requestBody: GenerateRequest) async throws -> GeneratedImage {
        var request = URLRequest(
            url: baseURL.appending(path: "chatAI/v1/image"),
            timeoutInterval: Self.requestTimeout
        )
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw GenerateImageError.invalidResponse
        }

        let decoder = JSONDecoder()
        guard (200..<300).contains(response.statusCode) else {
            let serverError = try? decoder.decode(ServerError.self, from: data)
            throw GenerateImageError.server(serverError?.error ?? "Could not generate an image.")
        }

        let payload = try decoder.decode(GeneratedImagePayload.self, from: data)
        guard let result = payload.data.first,
              let imageData = Data(base64Encoded: result.b64JSON),
              let mediaType = ImageFormat(mediaType: result.mediaType) else {
            throw GenerateImageError.invalidResponse
        }

        return GeneratedImage(
            data: imageData,
            format: mediaType,
            width: requestBody.width,
            height: requestBody.height,
            model: requestBody.model.rawValue
        )
    }
}

private struct GeneratedImagePayload: Decodable {
    let data: [ImageData]

    struct ImageData: Decodable {
        let b64JSON: String
        let mediaType: String

        private enum CodingKeys: String, CodingKey {
            case b64JSON = "b64_json"
            case mediaType = "media_type"
        }
    }
}

private struct ServerError: Decodable {
    let error: String
}

private extension ImageFormat {
    init?(mediaType: String) {
        switch mediaType.lowercased() {
        case "image/png": self = .png
        case "image/jpeg", "image/jpg": self = .jpeg
        case "image/webp": self = .webp
        default: return nil
        }
    }
}
