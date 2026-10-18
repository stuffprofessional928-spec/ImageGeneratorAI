import PhotosUI
import SwiftUI

private enum StudioPalette {
    static let background = Color(hex: 0xFAF9F6)
    static let accent = Color(hex: 0xEC750E)
    static let terracotta = Color(hex: 0xD46432)
    static let pink = Color(hex: 0xFCE7F3)
    static let gold = Color(hex: 0xF2BF65)
    static let ink = Color(hex: 0x2C2416)
    static let muted = Color(hex: 0x6F6558)
    static let line = Color(hex: 0xE7E0D6)
}

private struct PromptFieldFramePreferenceKey: PreferenceKey {
    static let defaultValue = CGRect.zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

private enum OptionSheet: String, Identifiable {
    case resolution
    case aspectRatio
    case dimensions
    case quality
    case format

    var id: String { rawValue }

    var title: String {
        switch self {
        case .resolution: "Resolution"
        case .aspectRatio: "Aspect ratio"
        case .dimensions: "Dimensions"
        case .quality: "Quality"
        case .format: "Output format"
        }
    }
}

struct GenerateScreen: View {
    @StateObject private var viewModel: GenerateViewModel
    @State private var isModelSheetPresented = false
    @State private var isPreviewPresented = false
    @State private var activeOption: OptionSheet?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var promptFieldFrame: CGRect = .zero
    @FocusState private var isPromptFocused: Bool

    init(viewModel: GenerateViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private var isGenerating: Bool { viewModel.phase == .generating }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0xF8E2CC).opacity(0.8), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 300)
            .frame(maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea()

            ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            header
                            modelChip
                            promptCard
                            referencePicker
                            settingsCard
                            generateButton
                            ImageStage(viewModel: viewModel)
                                .id("image-stage")
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                        .frame(maxWidth: 560)
                        .frame(maxWidth: .infinity)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: viewModel.phase) { _, phase in
                        if phase == .result {
                            withAnimation(.spring(response: 0.7, dampingFraction: 0.82)) {
                                scrollProxy.scrollTo("image-stage", anchor: .bottom)
                            }
                        }
                    }
            }
        }
        .coordinateSpace(name: "generate-screen")
        .onPreferenceChange(PromptFieldFramePreferenceKey.self) { promptFieldFrame = $0 }
        .simultaneousGesture(
            SpatialTapGesture().onEnded { tap in
                guard isPromptFocused, !promptFieldFrame.contains(tap.location) else { return }
                isPromptFocused = false
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(StudioPalette.background.ignoresSafeArea())
        .preferredColorScheme(.light)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if viewModel.generatedImage != nil && !isGenerating {
                    resultActions
            }
        }
        .sheet(isPresented: $isModelSheetPresented) {
            ModelSelectionSheet(selection: $viewModel.model)
                .presentationDetents([.height(380)])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $activeOption) { option in
            optionSheet(for: option)
                .presentationDetents(option == .dimensions ? [.large] : [.height(420)])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $isPreviewPresented) {
            if let image = viewModel.generatedImage, let uiImage = UIImage(data: image.data) {
                ImagePreview(image: uiImage)
            }
        }
        .onChange(of: selectedPhoto) { _, photo in
            guard let photo else { return }
            Task {
                do {
                    guard let data = try await photo.loadTransferable(type: Data.self) else {
                        viewModel.setStatusMessage("Could not load that image.")
                        return
                    }
                    viewModel.setReferenceImage(try ReferenceImageProcessor.prepare(data))
                    viewModel.setStatusMessage(nil)
                } catch {
                    viewModel.setStatusMessage(error.localizedDescription)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("IMAGE STUDIO")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(1.8)
                .foregroundStyle(StudioPalette.terracotta)
            Text("ImageGenerator")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(StudioPalette.ink)
            Text("Prompt, optional reference, one still.")
                .font(.system(size: 13))
                .foregroundStyle(StudioPalette.muted)
        }
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
    }

    private var modelChip: some View {
        Button {
            isPromptFocused = false
            isModelSheetPresented = true
        } label: {
            HStack(spacing: 9) {
                Circle().fill(StudioPalette.accent).frame(width: 8, height: 8)
                Text(viewModel.model.displayName)
                    .font(.system(size: 14, weight: .semibold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(StudioPalette.ink)
            .padding(.horizontal, 15)
            .frame(height: 36)
            .background(StudioPalette.gold, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isGenerating)
        .accessibilityLabel("Model, \(viewModel.model.displayName)")
    }

    private var promptCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("PROMPT")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(StudioPalette.terracotta)
                Spacer()
                Text("\(viewModel.promptWordCount)/\(GenerateViewModel.maximumPromptWordCount) words")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(StudioPalette.muted)
                    .accessibilityLabel("\(viewModel.promptWordCount) of \(GenerateViewModel.maximumPromptWordCount) words")
            }
            TextField("Describe the image you want to create", text: $viewModel.prompt, axis: .vertical)
                .font(.system(size: 15))
                .foregroundStyle(StudioPalette.ink)
                .lineLimit(4...12)
                .focused($isPromptFocused)
                .disabled(isGenerating)
                .accessibilityLabel("Image prompt")
                .accessibilityIdentifier("image-prompt-field")
                .background {
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: PromptFieldFramePreferenceKey.self,
                            value: geometry.frame(in: .named("generate-screen"))
                        )
                    }
                }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 154, alignment: .topLeading)
        .background(StudioPalette.pink, in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("prompt-card")
    }

    private var referencePicker: some View {
        let referenceImageData = viewModel.referenceImageData
        return HStack(spacing: 12) {
            if let referenceImageData, let image = UIImage(data: referenceImageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .accessibilityLabel("Selected reference image")
            } else {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(StudioPalette.accent)
                    .frame(width: 24)
            }

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(referenceImageData == nil ? "Add a reference image" : "Reference image")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(StudioPalette.ink)
                    Text(referenceImageData == nil ? "Optional. Text alone is enough." : "Attached · up to 1024 px")
                        .font(.system(size: 12))
                        .foregroundStyle(StudioPalette.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded { isPromptFocused = false })

            if referenceImageData != nil {
                Button {
                    viewModel.setReferenceImage(nil)
                    selectedPhoto = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(StudioPalette.ink)
                        .frame(width: 28, height: 28)
                        .background(StudioPalette.background, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove reference image")
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 56)
        .background(
            referenceImageData == nil ? Color.clear : Color.white,
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(StudioPalette.line, style: StrokeStyle(lineWidth: 1, dash: referenceImageData == nil ? [5, 4] : []))
        }
        .disabled(isGenerating)
    }

    private var settingsCard: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                optionButton(title: "Resolution", value: viewModel.resolution.rawValue, option: .resolution)
                optionButton(title: "Aspect ratio", value: viewModel.aspectRatio.rawValue, option: .aspectRatio)
            }
            HStack(spacing: 8) {
                optionButton(title: "Dimensions", value: viewModel.dimensions.label, option: .dimensions)
                    .accessibilityIdentifier("dimensions-option")
                optionButton(title: "Quality", value: viewModel.quality.rawValue, option: .quality)
            }
            optionButton(title: "Output format", value: viewModel.format.rawValue, option: .format)
                .frame(maxWidth: .infinity)
        }
        .padding(12)
        .background(.white, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(StudioPalette.line, lineWidth: 1))
    }

    private func optionButton(title: String, value: String, option: OptionSheet) -> some View {
        Button {
            isPromptFocused = false
            activeOption = option
        } label: {
            settingTile(title: title, value: value, showsChevron: true)
        }
        .buttonStyle(.plain)
        .disabled(isGenerating)
    }

    private func settingTile(title: String, value: String, showsChevron: Bool) -> some View {
        HStack(alignment: .center, spacing: 3) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 11))
                    .foregroundStyle(StudioPalette.muted)
                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(StudioPalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            Spacer(minLength: 0)
            if showsChevron {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(StudioPalette.muted)
            }
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
        .background(StudioPalette.background, in: RoundedRectangle(cornerRadius: 12))
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }

    private var generateButton: some View {
        Button {
            isPromptFocused = false
            Task { await viewModel.generate() }
        } label: {
            HStack(spacing: 10) {
                if isGenerating {
                    ProgressView().tint(.white)
                }
                Text(isGenerating ? "Generating" : "Generate")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(isGenerating ? StudioPalette.terracotta : StudioPalette.accent, in: Capsule())
            .shadow(color: StudioPalette.ink.opacity(0.08), radius: 8, y: 5)
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canGenerate)
        .opacity(viewModel.canGenerate ? 1 : 0.55)
    }

    private var resultActions: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Button { isPreviewPresented = true } label: {
                    Label("View", systemImage: "arrow.up.left.and.arrow.down.right")
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(.white, in: Capsule())
                        .overlay(Capsule().stroke(StudioPalette.line, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .foregroundStyle(StudioPalette.ink)

                Button {
                    Task { await viewModel.download() }
                } label: {
                    Label("Download", systemImage: "arrow.down.to.line")
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(StudioPalette.accent, in: Capsule())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
            }
            .font(.system(size: 15, weight: .semibold))

            if case .failed(let message) = viewModel.phase {
                VStack(alignment: .leading, spacing: 6) {
                    Text(message)
                        .font(.system(size: 13))
                        .foregroundStyle(StudioPalette.terracotta)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button("Try again") {
                        Task { await viewModel.generate() }
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(StudioPalette.terracotta)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .frame(maxWidth: .infinity)
            }

            if let status = viewModel.statusMessage {
                Text(status)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(StudioPalette.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background {
            LinearGradient(
                colors: [StudioPalette.background.opacity(0), StudioPalette.background, StudioPalette.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        }
    }

    @ViewBuilder
    private func optionSheet(for option: OptionSheet) -> some View {
        switch option {
        case .resolution:
            ChoiceSheet(title: option.title, selection: $viewModel.resolution)
        case .aspectRatio:
            ChoiceSheet(title: option.title, selection: $viewModel.aspectRatio)
        case .dimensions:
            DimensionsSelectionSheet(
                resolution: $viewModel.resolution,
                aspectRatio: $viewModel.aspectRatio
            )
        case .quality:
            ChoiceSheet(title: option.title, selection: $viewModel.quality)
        case .format:
            ChoiceSheet(title: option.title, selection: $viewModel.format)
        }
    }
}

private struct DimensionsOption: Identifiable {
    let resolution: ImageResolution
    let aspectRatio: ImageAspectRatio

    var id: String { "\(resolution.rawValue)-\(aspectRatio.rawValue)" }
    var dimensions: ImageDimensions {
        DimensionResolver.dimensions(resolution: resolution, aspectRatio: aspectRatio)
    }
    var label: String {
        "\(dimensions.label) · \(resolution.rawValue) · \(aspectRatio.rawValue)"
    }

    static var all: [DimensionsOption] {
        ImageResolution.allCases.flatMap { resolution in
            ImageAspectRatio.allCases.map { aspectRatio in
                DimensionsOption(resolution: resolution, aspectRatio: aspectRatio)
            }
        }
    }
}

private struct DimensionsSelectionSheet: View {
    @Binding var resolution: ImageResolution
    @Binding var aspectRatio: ImageAspectRatio
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Dimensions")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(StudioPalette.ink)
                Spacer()
                Button("Done") { dismiss() }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(StudioPalette.accent)
            }

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(DimensionsOption.all) { option in
                        let isSelected = option.resolution == resolution && option.aspectRatio == aspectRatio
                        Button {
                            resolution = option.resolution
                            aspectRatio = option.aspectRatio
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: option.aspectRatio.value.width == option.aspectRatio.value.height
                                      ? "square"
                                      : option.aspectRatio.value.width > option.aspectRatio.value.height
                                          ? "rectangle"
                                          : "rectangle.portrait")
                                    .font(.system(size: 19, weight: .medium))
                                    .foregroundStyle(StudioPalette.accent)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(option.dimensions.label)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(StudioPalette.ink)
                                    Text("\(option.resolution.rawValue) resolution · \(option.aspectRatio.rawValue) aspect")
                                        .font(.system(size: 13))
                                        .foregroundStyle(StudioPalette.muted)
                                }
                                Spacer()
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(StudioPalette.accent)
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, minHeight: 62)
                            .background(
                                isSelected ? StudioPalette.gold : StudioPalette.background,
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("dimension-\(option.id)")
                        .accessibilityLabel(option.label)
                    }
                }
            }
        }
        .padding(20)
        .background(.white)
    }
}

private struct ChoiceSheet<Option: RawRepresentable & CaseIterable & Identifiable>: View
where Option.RawValue == String, Option.AllCases: RandomAccessCollection {
    let title: String
    @Binding var selection: Option
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(StudioPalette.ink)
                Spacer()
                Button("Done") { dismiss() }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(StudioPalette.accent)
            }
            ForEach(Array(Option.allCases), id: \.id) { option in
                Button {
                    selection = option
                    dismiss()
                } label: {
                    HStack {
                        Text(option.rawValue)
                            .font(.system(size: 16, weight: .semibold))
                        Spacer()
                        if selection.id == option.id {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(StudioPalette.accent)
                        }
                    }
                    .foregroundStyle(StudioPalette.ink)
                    .padding(.horizontal, 16)
                    .frame(height: 54)
                    .background(
                        selection.id == option.id ? StudioPalette.gold : StudioPalette.background,
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .background(.white)
    }
}

private struct ModelSelectionSheet: View {
    @Binding var selection: GenerationModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Model")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(StudioPalette.ink)
                Spacer()
                Button("Done") { dismiss() }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(StudioPalette.accent)
            }
            .padding(.bottom, 2)

            ForEach(GenerationModel.allCases) { model in
                Button {
                    selection = model
                    dismiss()
                } label: {
                    HStack {
                        Text(model.displayName)
                            .font(.system(size: 16, weight: .semibold))
                        Spacer()
                        if selection == model {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(StudioPalette.accent)
                        }
                    }
                    .foregroundStyle(StudioPalette.ink)
                    .padding(.horizontal, 20)
                    .frame(height: 54)
                    .background(
                        selection == model ? StudioPalette.gold : StudioPalette.background,
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .background(.white)
    }
}

private struct ImageStage: View {
    @ObservedObject var viewModel: GenerateViewModel
    @State private var isRevealed = false
    @State private var sheenProgress: CGFloat = 0

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 12) {
                if viewModel.phase == .generating {
                    ProgressView()
                        .controlSize(.large)
                        .tint(StudioPalette.accent)
                        .frame(height: 56)
                    Text("Composing the still")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(StudioPalette.ink)
                    Text("\(viewModel.model.displayName) · \(viewModel.aspectRatio.rawValue) · \(viewModel.format.rawValue)")
                        .font(.system(size: 12))
                        .foregroundStyle(StudioPalette.muted)
                } else if let image = viewModel.generatedImage, let uiImage = UIImage(data: image.data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 176)
                        .overlay(alignment: .topLeading) {
                            Text("\(viewModel.aspectRatio.rawValue) · \(image.format.rawValue)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(StudioPalette.ink)
                                .padding(.horizontal, 11)
                                .padding(.vertical, 6)
                                .background(StudioPalette.gold, in: Capsule())
                                .padding(12)
                        }
                        .overlay { imageSheen }
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .opacity(isRevealed ? 1 : 0)
                        .scaleEffect(isRevealed ? 1 : 0.72)
                        .rotationEffect(.degrees(isRevealed ? 0 : -4))
                        .blur(radius: isRevealed ? 0 : 18)
                } else if case .failed(let message) = viewModel.phase {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 27, weight: .light))
                        .foregroundStyle(StudioPalette.terracotta)
                    Text(message)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(StudioPalette.terracotta)
                        .multilineTextAlignment(.center)
                    Text("Check the local studio server and try again.")
                        .font(.system(size: 12))
                        .foregroundStyle(StudioPalette.muted)
                        .multilineTextAlignment(.center)
                    retryButton
                } else {
                    Image(systemName: "sparkle")
                        .font(.system(size: 25, weight: .light))
                        .foregroundStyle(StudioPalette.accent)
                        .frame(height: 30)
                    Text("Your image will appear here")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(StudioPalette.ink)
                    Text("Generate to preview the still")
                        .font(.system(size: 12))
                        .foregroundStyle(StudioPalette.muted)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 176)
            .padding(16)
            .background {
                ZStack {
                    viewModel.phase == .generating
                        ? StudioPalette.gold.opacity(0.16)
                        : viewModel.generatedImage == nil && isFailure ? StudioPalette.pink : .white
                    if viewModel.phase == .generating {
                        Shimmer().clipShape(RoundedRectangle(cornerRadius: 22))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 22))
            }
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(StudioPalette.line, lineWidth: 1))

        }
        .onChange(of: viewModel.phase) { _, phase in
            if phase == .generating {
                isRevealed = false
                sheenProgress = 0
            } else if phase == .result {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.72)) {
                    isRevealed = true
                }
                withAnimation(.easeInOut(duration: 0.9).delay(0.15)) {
                    sheenProgress = 1
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var isFailure: Bool {
        if case .failed = viewModel.phase { return true }
        return false
    }

    private var retryButton: some View {
        Button("Try again") {
            Task { await viewModel.generate() }
        }
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(StudioPalette.terracotta)
        .padding(.horizontal, 18)
        .frame(height: 38)
        .overlay(Capsule().stroke(StudioPalette.terracotta, lineWidth: 1.3))
        .buttonStyle(.plain)
    }

    private var imageSheen: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.52), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: geometry.size.width * 0.4)
                .rotationEffect(.degrees(18))
                .offset(x: -geometry.size.width + sheenProgress * geometry.size.width * 1.8)
                .opacity(sheenProgress < 1 ? 1 : 0)
        }
        .clipped()
        .allowsHitTesting(false)
    }
}

private struct Shimmer: View {
    @State private var horizontalOffset: CGFloat = -1

    var body: some View {
        GeometryReader { geometry in
            LinearGradient(
                colors: [.clear, StudioPalette.gold.opacity(0.28), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geometry.size.width * 2)
            .rotationEffect(.degrees(12))
            .offset(x: horizontalOffset * geometry.size.width)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    horizontalOffset = 1
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct ImagePreview: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.18), in: Circle())
            }
            .padding(20)
            .accessibilityLabel("Close image preview")
        }
        .statusBarHidden()
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
