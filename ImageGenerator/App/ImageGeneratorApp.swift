import SwiftUI

@main
struct ImageGeneratorApp: App {
    private let viewModel: GenerateViewModel

    init() {
        let client = URLSessionImageAPIClient()
        viewModel = GenerateViewModel(generateImage: GenerateImageUseCase(client: client))
    }

    var body: some Scene {
        WindowGroup {
            GenerateScreen(viewModel: viewModel)
        }
    }
}
