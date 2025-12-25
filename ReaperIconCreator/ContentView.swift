import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var state = IconCreatorState()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                modeSelectionSection
                imageInputSection
                statePreviewSection
                toolbarIconsSection
                if state.stateImageMode == .automatic {
                    hsbAdjustmentsSection
                }
                trackIconsSection
                exportSection
            }
            .padding(24)
        }
        .frame(minWidth: 650, minHeight: 750)
        .overlay(alignment: .topTrailing) {
            if state.generateToolbarIcons {
                simulatorCornerView
                    .padding(16)
            }
        }
        .alert("Export Complete", isPresented: $state.exportSuccess) {
            Button("OK") { }
        } message: {
            Text("Icons have been exported successfully.")
        }
        .alert("Export Error", isPresented: Binding(
            get: { state.exportError != nil },
            set: { if !$0 { state.exportError = nil } }
        )) {
            Button("OK") { state.exportError = nil }
        } message: {
            Text(state.exportError ?? "Unknown error")
        }
    }

    // MARK: - Mode Selection

    private var modeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "State Generation Mode")

            Picker("Mode", selection: $state.stateImageMode) {
                Text("Automatic (HSB Adjustments)").tag(StateImageMode.automatic)
                Text("Manual (Separate Images)").tag(StateImageMode.manual)
            }
            .pickerStyle(.segmented)

            Text(state.stateImageMode == .automatic
                 ? "Generate Normal, Hover, and Active states from a single image using HSB adjustments."
                 : "Provide separate images for Normal, Hover, and Active states.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Image Input

    private var imageInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if state.stateImageMode == .automatic {
                automaticModeInput
            } else {
                manualModeInput
            }
        }
    }

    private var automaticModeInput: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Source Image")

            DropZoneView(image: $state.sourceImage)
                .frame(height: 180)

            if state.sourceImage != nil {
                Button("Clear Image") {
                    state.sourceImage = nil
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
            }
        }
    }

    private var manualModeInput: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "State Images (OFF)")
                Spacer()
                Text("Przeciagnij miedzy slotami | Kliknij aby zaznaczyc | Delete aby usunac")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 16) {
                DraggableStateDropZone(
                    title: "Normal",
                    slotID: .offNormal,
                    state: state
                )

                DraggableStateDropZone(
                    title: "Hover",
                    slotID: .offHover,
                    state: state
                )

                DraggableStateDropZone(
                    title: "Active",
                    slotID: .offActive,
                    state: state
                )
            }

            // ON state images (only shown when toggle is enabled)
            if state.generateToggleIcon {
                SectionHeader(title: "State Images (ON)")

                HStack(spacing: 16) {
                    DraggableStateDropZone(
                        title: "Normal",
                        slotID: .onNormal,
                        state: state
                    )

                    DraggableStateDropZone(
                        title: "Hover",
                        slotID: .onHover,
                        state: state
                    )

                    DraggableStateDropZone(
                        title: "Active",
                        slotID: .onActive,
                        state: state
                    )
                }
            }

            HStack {
                if state.normalStateImage != nil || state.hoverStateImage != nil || state.activeStateImage != nil {
                    Button("Clear All Images") {
                        state.normalStateImage = nil
                        state.hoverStateImage = nil
                        state.activeStateImage = nil
                        state.onNormalStateImage = nil
                        state.onHoverStateImage = nil
                        state.onActiveStateImage = nil
                        state.selectedSlot = nil
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                }

                Spacer()

                if state.selectedSlot != nil {
                    Button("Delete Selected") {
                        state.deleteSelectedImage()
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
        }
        .onDeleteCommand {
            state.deleteSelectedImage()
        }
    }

    // MARK: - State Preview

    private var statePreviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "State Preview")

            if state.stateImageMode == .automatic {
                StatePreviewRow(
                    sourceImage: state.sourceImage,
                    normalAdjustment: state.normalAdjustment,
                    hoverAdjustment: state.hoverAdjustment,
                    activeAdjustment: state.activeAdjustment
                )
            } else {
                ManualStatePreviewRow(
                    normalImage: state.normalStateImage,
                    hoverImage: state.hoverStateImage,
                    activeImage: state.activeStateImage
                )
            }
        }
    }

    // MARK: - Toolbar Icons

    private var toolbarIconsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SectionHeader(title: "Toolbar Icons")

                Spacer()

                Toggle("Generate", isOn: $state.generateToolbarIcons)
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }

            if state.generateToolbarIcons {
                VStack(spacing: 12) {
                    // Padding slider
                    HStack {
                        Text("Padding:")
                            .foregroundColor(.secondary)
                        Slider(value: $state.iconPadding, in: 0...0.35, step: 0.05)
                            .frame(maxWidth: 150)
                        Text("\(Int(state.iconPadding * 100))%")
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 40)
                    }

                    // Toggle ON/OFF option
                    HStack {
                        Toggle("Generate Toggle Icon (ON/OFF)", isOn: $state.generateToggleIcon)
                            .toggleStyle(.checkbox)

                        Text("Creates both iconname.png and iconname_on.png")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()
                    }

                    Divider()

                    ForEach(IconScale.allCases) { scale in
                        if state.stateImageMode == .automatic {
                            ToolbarIconPreview(
                                sourceImage: state.sourceImage,
                                scale: scale,
                                normalAdjustment: state.normalAdjustment,
                                hoverAdjustment: state.hoverAdjustment,
                                activeAdjustment: state.activeAdjustment,
                                padding: state.iconPadding,
                                isSelected: state.selectedToolbarScales.contains(scale),
                                onToggle: { toggleScale(scale) }
                            )
                        } else {
                            ToolbarIconPreviewManual(
                                normalImage: state.normalStateImage,
                                hoverImage: state.hoverStateImage,
                                activeImage: state.activeStateImage,
                                scale: scale,
                                padding: state.iconPadding,
                                isSelected: state.selectedToolbarScales.contains(scale),
                                onToggle: { toggleScale(scale) }
                            )
                        }
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }

    private func toggleScale(_ scale: IconScale) {
        if state.selectedToolbarScales.contains(scale) {
            state.selectedToolbarScales.remove(scale)
        } else {
            state.selectedToolbarScales.insert(scale)
        }
    }

    // MARK: - HSB Adjustments

    private var hsbAdjustmentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SectionHeader(title: "State Adjustments (OFF)")

                Spacer()

                Button("Reset All") {
                    state.normalAdjustment = .normal
                    state.hoverAdjustment = .hover
                    state.activeAdjustment = .active
                    state.onNormalAdjustment = .onNormal
                    state.onHoverAdjustment = .onHover
                    state.onActiveAdjustment = .onActive
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundColor(.accentColor)
            }

            VStack(spacing: 12) {
                HSBAdjustmentView(
                    title: "Normal",
                    adjustment: $state.normalAdjustment,
                    defaultAdjustment: .normal
                )

                Divider()

                HSBAdjustmentView(
                    title: "Hover",
                    adjustment: $state.hoverAdjustment,
                    defaultAdjustment: .hover
                )

                Divider()

                HSBAdjustmentView(
                    title: "Active",
                    adjustment: $state.activeAdjustment,
                    defaultAdjustment: .active
                )
            }
            .padding()
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)

            // ON state adjustments (only shown when toggle is enabled)
            if state.generateToggleIcon {
                SectionHeader(title: "State Adjustments (ON)")

                VStack(spacing: 12) {
                    HSBAdjustmentView(
                        title: "Normal",
                        adjustment: $state.onNormalAdjustment,
                        defaultAdjustment: .onNormal
                    )

                    Divider()

                    HSBAdjustmentView(
                        title: "Hover",
                        adjustment: $state.onHoverAdjustment,
                        defaultAdjustment: .onHover
                    )

                    Divider()

                    HSBAdjustmentView(
                        title: "Active",
                        adjustment: $state.onActiveAdjustment,
                        defaultAdjustment: .onActive
                    )
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }

    // MARK: - Simulator Corner View

    private var simulatorCornerView: some View {
        VStack(spacing: 4) {
            Text("Simulator")
                .font(.caption2)
                .foregroundColor(.secondary)

            if state.stateImageMode == .automatic {
                ToolbarSimulatorCompact(
                    sourceImage: state.sourceImage,
                    scale: .scale150,
                    normalAdjustment: state.normalAdjustment,
                    hoverAdjustment: state.hoverAdjustment,
                    activeAdjustment: state.activeAdjustment,
                    onNormalAdjustment: state.onNormalAdjustment,
                    onHoverAdjustment: state.onHoverAdjustment,
                    onActiveAdjustment: state.onActiveAdjustment,
                    isToggleIcon: state.generateToggleIcon,
                    padding: state.iconPadding
                )
            } else {
                ToolbarSimulatorManualCompact(
                    normalImage: state.normalStateImage,
                    hoverImage: state.hoverStateImage,
                    activeImage: state.activeStateImage,
                    onNormalImage: state.onNormalStateImage,
                    onHoverImage: state.onHoverStateImage,
                    onActiveImage: state.onActiveStateImage,
                    scale: .scale150,
                    isToggleIcon: state.generateToggleIcon,
                    padding: state.iconPadding
                )
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
    }

    // MARK: - Track Icons

    private var trackIconsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SectionHeader(title: "Track Icons")

                Spacer()

                Toggle("Generate", isOn: $state.generateTrackIcons)
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }

            if state.generateTrackIcons {
                HStack(spacing: 24) {
                    let sourceForTrack = state.stateImageMode == .automatic
                        ? state.sourceImage
                        : state.normalStateImage

                    ForEach(TrackIconSize.allCases) { size in
                        TrackIconPreview(
                            sourceImage: sourceForTrack,
                            size: size,
                            isSelected: state.selectedTrackSizes.contains(size),
                            onToggle: {
                                if state.selectedTrackSizes.contains(size) {
                                    state.selectedTrackSizes.remove(size)
                                } else {
                                    state.selectedTrackSizes.insert(size)
                                }
                            }
                        )
                    }
                    Spacer()
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }

    // MARK: - Export

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Export")

            HStack {
                Text("Icon Name:")
                    .foregroundColor(.secondary)

                TextField("my_icon", text: $state.iconName)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 200)
            }

            HStack {
                Text("REAPER Path:")
                    .foregroundColor(.secondary)

                if let path = state.reaperPath {
                    Text(path.path)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.middle)
                } else {
                    Text("Not found")
                        .foregroundColor(.orange)
                }

                Button("Select...") {
                    selectReaperPath()
                }
                .buttonStyle(.bordered)
            }

            HStack(spacing: 16) {
                Button(action: exportToFolder) {
                    Label("Export to Folder...", systemImage: "folder")
                }
                .buttonStyle(.bordered)
                .disabled(!state.canExport)

                Button(action: exportToReaper) {
                    Label("Export to REAPER", systemImage: "arrow.right.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!state.canExport || state.reaperPath == nil)
            }

            if !state.canExport {
                exportStatusMessage
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }

    @ViewBuilder
    private var exportStatusMessage: some View {
        if state.stateImageMode == .automatic && state.sourceImage == nil {
            Text("Load an image to enable export")
                .font(.caption)
                .foregroundColor(.orange)
        } else if state.stateImageMode == .manual && !state.hasValidManualStates {
            Text("Load all three state images (Normal, Hover, Active) to enable export")
                .font(.caption)
                .foregroundColor(.orange)
        }
    }

    // MARK: - Actions

    private func selectReaperPath() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select your REAPER application support folder"
        panel.prompt = "Select"

        if let currentPath = state.reaperPath {
            panel.directoryURL = currentPath
        } else {
            let home = FileManager.default.homeDirectoryForCurrentUser
            panel.directoryURL = home.appendingPathComponent("Library/Application Support")
        }

        if panel.runModal() == .OK, let url = panel.url {
            state.reaperPath = url
        }
    }

    private func exportToFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.message = "Select destination folder for icons"
        panel.prompt = "Export Here"

        if panel.runModal() == .OK, let url = panel.url {
            performExport(to: url)
        }
    }

    private func exportToReaper() {
        guard let reaperPath = state.reaperPath else { return }
        let dataPath = reaperPath.appendingPathComponent("Data")
        performExport(to: dataPath)
    }

    private func performExport(to url: URL) {
        state.isExporting = true

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                if state.stateImageMode == .automatic {
                    guard let sourceImage = state.sourceImage else { return }
                    try IconExporter.shared.exportToFolder(
                        sourceImage: sourceImage,
                        iconName: state.iconName,
                        destinationURL: url,
                        toolbarScales: state.selectedToolbarScales,
                        trackSizes: state.selectedTrackSizes,
                        generateToolbar: state.generateToolbarIcons,
                        generateTrack: state.generateTrackIcons,
                        normalAdjustment: state.normalAdjustment,
                        hoverAdjustment: state.hoverAdjustment,
                        activeAdjustment: state.activeAdjustment,
                        padding: state.iconPadding,
                        generateToggle: state.generateToggleIcon,
                        onNormalAdjustment: state.onNormalAdjustment,
                        onHoverAdjustment: state.onHoverAdjustment,
                        onActiveAdjustment: state.onActiveAdjustment
                    )
                } else {
                    guard let normalImage = state.normalStateImage,
                          let hoverImage = state.hoverStateImage,
                          let activeImage = state.activeStateImage else { return }
                    try IconExporter.shared.exportToFolderManual(
                        normalImage: normalImage,
                        hoverImage: hoverImage,
                        activeImage: activeImage,
                        iconName: state.iconName,
                        destinationURL: url,
                        toolbarScales: state.selectedToolbarScales,
                        trackSizes: state.selectedTrackSizes,
                        generateToolbar: state.generateToolbarIcons,
                        generateTrack: state.generateTrackIcons,
                        padding: state.iconPadding,
                        generateToggle: state.generateToggleIcon,
                        onNormalImage: state.onNormalStateImage,
                        onHoverImage: state.onHoverStateImage,
                        onActiveImage: state.onActiveStateImage
                    )
                }

                DispatchQueue.main.async {
                    state.isExporting = false
                    state.exportSuccess = true
                }
            } catch {
                DispatchQueue.main.async {
                    state.isExporting = false
                    state.exportError = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.title3)
            .fontWeight(.semibold)
    }
}

struct StateDropZone: View {
    let title: String
    @Binding var image: NSImage?

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            SmallDropZoneView(image: $image)
                .frame(height: 120)
        }
    }
}

struct DraggableStateDropZone: View {
    let title: String
    let slotID: ManualSlotID
    @ObservedObject var state: IconCreatorState
    @State private var isTargeted = false

    private var image: NSImage? {
        state.image(for: slotID)
    }

    private var isSelected: Bool {
        state.selectedSlot == slotID
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: isSelected ? 3 : 2, dash: image == nil ? [6] : [])
                    )
                    .foregroundColor(borderColor)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(backgroundColor)
                    )

                if let img = image {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(8)
                        .onDrag {
                            NSItemProvider(object: slotID.rawValue as NSString)
                        }
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "photo")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)

                        Text("Drop or Click")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 120)
            .onDrop(of: [.text, .image, .fileURL], isTargeted: $isTargeted) { providers in
                handleDrop(providers: providers)
            }
            .onTapGesture {
                if image != nil {
                    state.selectedSlot = isSelected ? nil : slotID
                } else {
                    openFilePicker()
                }
            }
        }
    }

    private var borderColor: Color {
        if isSelected {
            return .accentColor
        } else if isTargeted {
            return .accentColor
        } else {
            return .secondary.opacity(0.5)
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.15)
        } else if isTargeted {
            return Color.accentColor.opacity(0.1)
        } else {
            return Color.secondary.opacity(0.05)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        // Check for internal drag (slot ID)
        if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.text.identifier) { item, _ in
                DispatchQueue.main.async {
                    if let data = item as? Data,
                       let slotString = String(data: data, encoding: .utf8),
                       let sourceSlot = ManualSlotID(rawValue: slotString) {
                        state.moveImage(from: sourceSlot, to: slotID)
                        state.selectedSlot = nil
                    }
                }
            }
            return true
        }

        // External image drop
        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.image.identifier) { item, _ in
                DispatchQueue.main.async {
                    if let url = item as? URL {
                        loadImage(from: url)
                    } else if let data = item as? Data, let nsImage = NSImage(data: data) {
                        state.setImage(nsImage, for: slotID)
                    }
                }
            }
            return true
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, _ in
                DispatchQueue.main.async {
                    if let data = item as? Data,
                       let urlString = String(data: data, encoding: .utf8),
                       let url = URL(string: urlString) {
                        loadImage(from: url)
                    } else if let url = item as? URL {
                        loadImage(from: url)
                    }
                }
            }
            return true
        }

        return false
    }

    private func loadImage(from url: URL) {
        if let nsImage = NSImage(contentsOf: url) {
            state.setImage(nsImage, for: slotID)
        }
    }

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.png, .jpeg, .webP, .tiff, .bmp, .gif]

        if panel.runModal() == .OK, let url = panel.url {
            loadImage(from: url)
        }
    }
}

struct SmallDropZoneView: View {
    @Binding var image: NSImage?
    @State private var isTargeted = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 2, dash: [6])
                )
                .foregroundColor(isTargeted ? .accentColor : .secondary.opacity(0.5))
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isTargeted ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.05))
                )

            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(8)
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "photo")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)

                    Text("Drop or Click")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onDrop(of: [.image, .fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
        }
        .onTapGesture {
            openFilePicker()
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.image.identifier) { item, _ in
                DispatchQueue.main.async {
                    if let url = item as? URL {
                        loadImage(from: url)
                    } else if let data = item as? Data, let nsImage = NSImage(data: data) {
                        self.image = nsImage
                    }
                }
            }
            return true
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, _ in
                DispatchQueue.main.async {
                    if let data = item as? Data,
                       let urlString = String(data: data, encoding: .utf8),
                       let url = URL(string: urlString) {
                        loadImage(from: url)
                    } else if let url = item as? URL {
                        loadImage(from: url)
                    }
                }
            }
            return true
        }

        return false
    }

    private func loadImage(from url: URL) {
        if let nsImage = NSImage(contentsOf: url) {
            self.image = nsImage
        }
    }

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.png, .jpeg, .webP, .tiff, .bmp, .gif]

        if panel.runModal() == .OK, let url = panel.url {
            loadImage(from: url)
        }
    }
}

struct ManualStatePreviewRow: View {
    let normalImage: NSImage?
    let hoverImage: NSImage?
    let activeImage: NSImage?

    private let processor = ImageProcessor.shared
    private let previewSize = 60

    var body: some View {
        HStack(spacing: 20) {
            statePreview(title: "Normal", image: normalImage)
            statePreview(title: "Hover", image: hoverImage)
            statePreview(title: "Active", image: activeImage)
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func statePreview(title: String, image: NSImage?) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            if let source = image {
                let squared = processor.cropToSquare(source)
                let scaled = processor.scaleImage(squared, to: NSSize(width: previewSize, height: previewSize))

                ZStack {
                    CheckerboardBackground()
                        .frame(width: CGFloat(previewSize), height: CGFloat(previewSize))
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    Image(nsImage: scaled)
                        .interpolation(.high)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                )
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: CGFloat(previewSize), height: CGFloat(previewSize))
                    .overlay(
                        Image(systemName: "questionmark")
                            .foregroundColor(.secondary)
                    )
            }
        }
    }
}

struct ToolbarIconPreviewManual: View {
    let normalImage: NSImage?
    let hoverImage: NSImage?
    let activeImage: NSImage?
    let scale: IconScale
    var padding: Double = 0
    let isSelected: Bool
    let onToggle: () -> Void

    private let processor = ImageProcessor.shared

    var body: some View {
        HStack(spacing: 12) {
            Toggle(isOn: Binding(get: { isSelected }, set: { _ in onToggle() })) {
                Text(scale.displayName)
                    .font(.system(.body, design: .monospaced))
                    .frame(width: 50, alignment: .leading)
            }
            .toggleStyle(.checkbox)

            if let normal = normalImage, let hover = hoverImage, let active = activeImage {
                let toolbarIcon = processor.generateToolbarIconManual(
                    normalImage: normal,
                    hoverImage: hover,
                    activeImage: active,
                    scale: scale,
                    padding: padding
                )

                ZStack {
                    CheckerboardBackground()
                        .frame(width: scale.totalSize.width, height: scale.totalSize.height)
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    Image(nsImage: toolbarIcon)
                        .interpolation(.high)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                )

                HStack(spacing: 4) {
                    Text("\(Int(scale.totalSize.width))x\(Int(scale.totalSize.height))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Load all state images")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .opacity(isSelected ? 1.0 : 0.5)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
