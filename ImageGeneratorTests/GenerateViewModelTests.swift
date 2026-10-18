import Foundation
import Testing
@testable import ImageGenerator

@Test @MainActor func viewModelStartsWithPlaceholderAndDefaultOptions() async {
    let client = StubImageAPIClient()
    let viewModel = makeViewModel(client: client)

    #expect(viewModel.phase == .idle)
    #expect(viewModel.prompt == "A sunlit terracotta courtyard with olive trees, warm amber light, film still")
    #expect(viewModel.model == .qwenImage)
    #expect(viewModel.dimensions == ImageDimensions(width: 1024, height: 1024))
    let callCount = await client.callCount
    #expect(callCount == 0)
}

@Test @MainActor func successfulGenerationReachesResultWithImage() async {
    let image = GeneratedImage(
        data: Data([1, 2, 3]),
        format: .png,
        width: 1024,
        height: 1024,
        model: GenerationModel.qwenImage.rawValue
    )
    let client = StubImageAPIClient(image: image)
    let viewModel = makeViewModel(client: client)

    await viewModel.generate()

    #expect(viewModel.phase == .result)
    #expect(viewModel.generatedImage == image)
    let callCount = await client.callCount
    #expect(callCount == 1)
}

@Test @MainActor func generationCanBeStartedAgainAfterSuccess() async {
    let client = StubImageAPIClient()
    let viewModel = makeViewModel(client: client)

    await viewModel.generate()
    #expect(viewModel.canGenerate)

    await viewModel.generate()

    let callCount = await client.callCount
    #expect(callCount == 2)
    #expect(viewModel.phase == .result)
}

@Test @MainActor func failureKeepsPromptAndReportsError() async {
    let client = StubImageAPIClient(failure: GenerateImageError.server("Studio is unavailable."))
    let viewModel = makeViewModel(client: client)
    let prompt = viewModel.prompt

    await viewModel.generate()

    #expect(viewModel.phase == .failed("Studio is unavailable."))
    #expect(viewModel.prompt == prompt)
    #expect(viewModel.generatedImage == nil)
}

@Test @MainActor func aSecondGenerateWhileBusyIsIgnored() async {
    let client = StubImageAPIClient(delay: .milliseconds(150))
    let viewModel = makeViewModel(client: client)
    let firstGeneration = Task { await viewModel.generate() }
    try? await Task.sleep(for: .milliseconds(15))

    await viewModel.generate()
    await firstGeneration.value

    let callCount = await client.callCount
    #expect(callCount == 1)
    #expect(viewModel.phase == .result)
}

@Test @MainActor func blankPromptCannotGenerate() async {
    let client = StubImageAPIClient()
    let viewModel = makeViewModel(client: client)
    viewModel.prompt = " \n "

    await viewModel.generate()

    #expect(viewModel.phase == .failed(GenerateImageError.emptyPrompt.localizedDescription))
    let callCount = await client.callCount
    #expect(callCount == 0)
}

@Test @MainActor func promptIsLimitedToThreeThousandWords() {
    let viewModel = makeViewModel(client: StubImageAPIClient())

    viewModel.prompt = String(repeating: "word ", count: GenerateViewModel.maximumPromptWordCount + 1)

    #expect(viewModel.promptWordCount == 3_000)
    #expect(viewModel.prompt == String(repeating: "word ", count: 2_999) + "word")

    viewModel.prompt = String(repeating: "another ", count: GenerateViewModel.maximumPromptWordCount)
    #expect(viewModel.promptWordCount == GenerateViewModel.maximumPromptWordCount)
}

@MainActor
private func makeViewModel(client: any ImageAPIClient) -> GenerateViewModel {
    GenerateViewModel(generateImage: GenerateImageUseCase(client: client))
}

private actor StubImageAPIClient: ImageAPIClient {
    private(set) var callCount = 0
    private let image: GeneratedImage
    private let failure: GenerateImageError?
    private let delay: Duration

    init(
        image: GeneratedImage = GeneratedImage(
            data: Data([1]),
            format: .png,
            width: 1024,
            height: 1024,
            model: GenerationModel.qwenImage.rawValue
        ),
        failure: GenerateImageError? = nil,
        delay: Duration = .zero
    ) {
        self.image = image
        self.failure = failure
        self.delay = delay
    }

    func generate(_ request: GenerateRequest) async throws -> GeneratedImage {
        callCount += 1
        if delay != .zero {
            try await Task.sleep(for: delay)
        }
        if let failure {
            throw failure
        }
        return image
    }
}
