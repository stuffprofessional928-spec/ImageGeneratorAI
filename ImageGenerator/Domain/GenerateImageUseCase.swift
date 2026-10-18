import Foundation

protocol ImageAPIClient: Sendable {
    func generate(_ request: GenerateRequest) async throws -> GeneratedImage
}

struct GenerateImageUseCase {
    private let client: any ImageAPIClient

    init(client: any ImageAPIClient) {
        self.client = client
    }

    func execute(
        prompt: String,
        model: GenerationModel,
        resolution: ImageResolution,
        aspectRatio: ImageAspectRatio,
        quality: ImageQuality,
        format: ImageFormat,
        referenceImageData: Data?
    ) async throws -> GeneratedImage {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            throw GenerateImageError.emptyPrompt
        }

        let dimensions = DimensionResolver.dimensions(resolution: resolution, aspectRatio: aspectRatio)
        let request = GenerateRequest(
            prompt: trimmedPrompt,
            model: model,
            resolution: resolution,
            aspectRatio: aspectRatio,
            width: dimensions.width,
            height: dimensions.height,
            quality: quality,
            format: format,
            referenceImageBase64: referenceImageData?.base64EncodedString()
        )
        return try await client.generate(request)
    }
}
