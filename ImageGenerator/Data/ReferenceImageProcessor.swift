import UIKit

enum ReferenceImageProcessor {
    static func prepare(_ data: Data) throws -> Data {
        guard let image = UIImage(data: data), let cgImage = image.cgImage else {
            throw GenerateImageError.invalidResponse
        }

        let longestEdge = max(cgImage.width, cgImage.height)
        let scale = min(1, 1024 / CGFloat(longestEdge))
        let size = CGSize(
            width: CGFloat(cgImage.width) * scale,
            height: CGFloat(cgImage.height) * scale
        )
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.jpegData(withCompressionQuality: 0.82) { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
