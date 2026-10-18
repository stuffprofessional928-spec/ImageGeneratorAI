import Photos

protocol ImageDownloadService: Sendable {
    func save(_ image: GeneratedImage) async throws
}

struct PhotoLibraryImageSaver: ImageDownloadService {
    func save(_ image: GeneratedImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw ImageDownloadError.permissionDenied
        }

        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(
                with: .photo,
                data: image.data,
                options: PHAssetResourceCreationOptions()
            )
        }
    }
}

enum ImageDownloadError: LocalizedError {
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            "Allow Photos access in Settings to save this image."
        }
    }
}
