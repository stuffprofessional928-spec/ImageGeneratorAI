import Foundation
import Testing
@testable import ImageGenerator

@Test func urlSessionClientDecodesImageAndMetadata() async throws {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [StubURLProtocol.self]
    let session = URLSession(configuration: configuration)
    let client = URLSessionImageAPIClient(
        baseURL: URL(string: "https://api.test")!,
        session: session
    )
    let request = GenerateRequest(
        prompt: "Courtyard",
        model: .qwenImage,
        resolution: .oneK,
        aspectRatio: .square,
        width: 1024,
        height: 1024,
        quality: .standard,
        format: .png,
        image: ""
    )

    let image = try await client.generate(request)

    #expect(image.data == Data([255, 216, 255, 217]))
    #expect(image.format == .jpeg)
    #expect(image.width == 1024)
    #expect(image.height == 1024)
    #expect(image.model == "qwen/qwen-image-2.1-turbo")
}

private final class StubURLProtocol: URLProtocol {
    private static let responseBody = Data(
        #"{"created":0,"data":[{"b64_json":"/9j/2Q==","media_type":"image/jpeg"}],"usage":{"total_tokens":0}}"#.utf8
    )

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url,
              let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
              ) else {
            client?.urlProtocol(self, didFailWithError: GenerateImageError.invalidResponse)
            return
        }

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.responseBody)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
