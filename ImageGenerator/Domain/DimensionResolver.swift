import Foundation

enum DimensionResolver {
    static func dimensions(
        resolution: ImageResolution,
        aspectRatio: ImageAspectRatio
    ) -> ImageDimensions {
        let ratio = aspectRatio.value
        let base = resolution.baseEdge

        if ratio.width >= ratio.height {
            return ImageDimensions(
                width: base,
                height: Int((Double(base) * Double(ratio.height) / Double(ratio.width)).rounded())
            )
        }

        return ImageDimensions(
            width: Int((Double(base) * Double(ratio.width) / Double(ratio.height)).rounded()),
            height: base
        )
    }
}
