import Foundation
import SwiftUI

@MainActor
final class GenerateViewModel: ObservableObject {
    static let maximumPromptWordCount = 3_000

    enum Phase: Equatable {
        case idle
        case generating
        case result
        case failed(String)
    }

    @Published var prompt = "A sunlit terracotta courtyard with olive trees, warm amber light, film still" {
        didSet {
            let limitedPrompt = Self.promptLimitedToWordCount(prompt)
            if prompt != limitedPrompt {
                prompt = limitedPrompt
            }
        }
    }
    @Published var model = GenerationModel.qwenImage
    @Published var resolution = ImageResolution.oneK
    @Published var aspectRatio = ImageAspectRatio.square
    @Published var quality = ImageQuality.standard
    @Published var format = ImageFormat.png
    @Published private(set) var referenceImageData: Data?
    @Published private(set) var generatedImage: GeneratedImage?
    @Published private(set) var phase = Phase.idle
    @Published private(set) var statusMessage: String?

    private let generateImage: GenerateImageUseCase
    private let imageDownloader: any ImageDownloadService

    var dimensions: ImageDimensions {
        DimensionResolver.dimensions(resolution: resolution, aspectRatio: aspectRatio)
    }

    var canGenerate: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && phase != .generating
    }

    var promptWordCount: Int {
        prompt.split(whereSeparator: \.isWhitespace).count
    }

    init(
        generateImage: GenerateImageUseCase,
        imageDownloader: any ImageDownloadService = PhotoLibraryImageSaver()
    ) {
        self.generateImage = generateImage
        self.imageDownloader = imageDownloader
    }

    func setReferenceImage(_ data: Data?) {
        referenceImageData = data
    }

    func setStatusMessage(_ message: String?) {
        statusMessage = message
    }

    private static func promptLimitedToWordCount(_ prompt: String) -> String {
        var wordCount = 0
        var isInsideWord = false

        for index in prompt.indices {
            if prompt[index].isWhitespace {
                isInsideWord = false
            } else if !isInsideWord {
                guard wordCount < maximumPromptWordCount else {
                    return String(prompt[..<index]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
                wordCount += 1
                isInsideWord = true
            }
        }

        return prompt
    }

    func generate() async {
        guard phase != .generating else { return }
        guard canGenerate else {
            phase = .failed(GenerateImageError.emptyPrompt.localizedDescription)
            return
        }

        phase = .generating
        statusMessage = nil

        do {
            let image = try await generateImage.execute(
                prompt: prompt,
                model: model,
                resolution: resolution,
                aspectRatio: aspectRatio,
                quality: quality,
                format: format
            )
            withAnimation(.easeInOut(duration: 0.45)) {
                generatedImage = image
                phase = .result
            }
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func download() async {
        guard let generatedImage else { return }
        do {
            try await imageDownloader.save(generatedImage)
            statusMessage = "Saved to Photos."
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}
