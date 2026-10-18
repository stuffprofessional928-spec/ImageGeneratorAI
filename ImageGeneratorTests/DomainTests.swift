import Foundation
import Testing
@testable import ImageGenerator

@Test func resolvesEveryResolutionAndAspectRatio() {
    let expected: [ImageResolution: [ImageAspectRatio: ImageDimensions]] = [
        .oneK: [
            .square: ImageDimensions(width: 1024, height: 1024),
            .portrait: ImageDimensions(width: 819, height: 1024),
            .landscape: ImageDimensions(width: 1024, height: 683),
            .widescreen: ImageDimensions(width: 1024, height: 576),
            .tall: ImageDimensions(width: 576, height: 1024)
        ],
        .twoK: [
            .square: ImageDimensions(width: 2048, height: 2048),
            .portrait: ImageDimensions(width: 1638, height: 2048),
            .landscape: ImageDimensions(width: 2048, height: 1365),
            .widescreen: ImageDimensions(width: 2048, height: 1152),
            .tall: ImageDimensions(width: 1152, height: 2048)
        ]
    ]

    for resolution in ImageResolution.allCases {
        for aspectRatio in ImageAspectRatio.allCases {
            #expect(
                DimensionResolver.dimensions(resolution: resolution, aspectRatio: aspectRatio)
                    == expected[resolution]?[aspectRatio]
            )
        }
    }
}

@Test func requestEncodingOmitsMissingReferenceAndKeepsContractKeys() throws {
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
    let data = try JSONEncoder().encode(request)
    let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

    #expect(Set(json.keys) == ["prompt", "model", "resolution", "aspect_ratio", "dimensions", "image", "quality", "output"])
    #expect(json["aspect_ratio"] as? String == "1:1")
    #expect(json["dimensions"] as? String == "1024x1024")
    #expect(json["image"] as? String == "")
    #expect(json["model"] as? String == "qwen/qwen-image-2.1-turbo")
    #expect(json["quality"] as? String == "standard")
    #expect(json["output"] as? String == "png")
}

@Test func requestEncodingUsesFluxModelIdentifier() throws {
    let request = GenerateRequest(
        prompt: "Courtyard",
        model: .fluxImage,
        resolution: .twoK,
        aspectRatio: .tall,
        width: 1152,
        height: 2048,
        quality: .high,
        format: .jpeg,
        image: ""
    )
    let data = try JSONEncoder().encode(request)
    let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

    #expect(json["image"] as? String == "")
    #expect(json["dimensions"] as? String == "1152x2048")
    #expect(json["model"] as? String == "black-forest-labs/flux-3-image-klein")
    #expect(json["quality"] as? String == "high")
    #expect(json["output"] as? String == "jpeg")
}

@Test func emptyAndWhitespacePromptsAreRejectedBeforeCallingClient() async {
    let client = CountingImageAPIClient()
    let useCase = GenerateImageUseCase(client: client)

    for prompt in ["", " \n\t "] {
        do {
            _ = try await useCase.execute(
                prompt: prompt,
                model: .qwenImage,
                resolution: .oneK,
                aspectRatio: .square,
                quality: .standard,
                format: .png
            )
            Issue.record("Expected an empty prompt to be rejected.")
        } catch let error as GenerateImageError {
            #expect(error == .emptyPrompt)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    let callCount = await client.callCount
    #expect(callCount == 0)
}

private actor CountingImageAPIClient: ImageAPIClient {
    private(set) var callCount = 0

    func generate(_ request: GenerateRequest) async throws -> GeneratedImage {
        callCount += 1
        return GeneratedImage(data: Data(), format: request.format, width: request.width, height: request.height, model: request.model.rawValue)
    }
}
