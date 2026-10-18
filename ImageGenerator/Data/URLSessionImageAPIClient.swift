import Foundation

final class URLSessionImageAPIClient: ImageAPIClient, @unchecked Sendable {
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL = URL(string: "http://127.0.0.1:8787")!, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func generate(_ requestBody: GenerateRequest) async throws -> GeneratedImage {
        var request = URLRequest(url: baseURL.appending(path: "/v1/generate"))
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
        guard let imageData = Data(base64Encoded: payload.imageBase64) else {
            throw GenerateImageError.invalidResponse
        }

        return GeneratedImage(
            data: imageData,
            format: ImageFormat(rawValue: payload.format) ?? requestBody.format,
            width: payload.width,
            height: payload.height,
            model: payload.model
        )
    }
}

private struct GeneratedImagePayload: Decodable {
    let imageBase64: String
    let format: String
    let width: Int
    let height: Int
    let model: String
}

private struct ServerError: Decodable {
    let error: String
}
