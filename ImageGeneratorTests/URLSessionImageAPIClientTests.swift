import Foundation
import Testing
@testable import ImageGenerator

@Test func urlSessionClientDecodesImageAndMetadata() async throws {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [StubURLProtocol.self]
    let session = URLSession(configuration: configuration)
    let client = URLSessionImageAPIClient(
        baseURL: URL(string: "https://mock.image.test")!,
        session: session
    )
    let request = GenerateRequest(
        prompt: "Courtyard",
        model: .gpt4o,
        resolution: .oneK,
        aspectRatio: .square,
        width: 1024,
        height: 1024,
        quality: .standard,
        format: .png,
        referenceImageBase64: nil
    )

    let image = try await client.generate(request)

    #expect(image.data == Data([137, 80, 78, 71, 13, 10, 26, 10]))
    #expect(image.format == .png)
    #expect(image.width == 1024)
    #expect(image.height == 1024)
    #expect(image.model == "GPT-4o")
}

private final class StubURLProtocol: URLProtocol {
    private static let responseBody = Data(
        #"{"imageBase64":"iVBORw0KGgo=","format":"PNG","width":1024,"height":1024,"model":"GPT-4o"}"#.utf8
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
