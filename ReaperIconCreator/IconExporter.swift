import AppKit
import UniformTypeIdentifiers

enum ExportError: LocalizedError {
    case noImage
    case invalidName
    case createDirectoryFailed(String)
    case saveFailed(String)
    case noScalesSelected
    case noSizesSelected

    var errorDescription: String? {
        switch self {
        case .noImage:
            return "No source image loaded"
        case .invalidName:
            return "Invalid icon name"
        case .createDirectoryFailed(let path):
            return "Failed to create directory: \(path)"
        case .saveFailed(let path):
            return "Failed to save image: \(path)"
        case .noScalesSelected:
            return "No toolbar icon scales selected"
        case .noSizesSelected:
            return "No track icon sizes selected"
        }
    }
}

class IconExporter {
    static let shared = IconExporter()
    private let processor = ImageProcessor.shared

    private init() {}

    // MARK: - Automatic Mode Export

    func exportToFolder(
        sourceImage: NSImage,
        iconName: String,
        destinationURL: URL,
        toolbarScales: Set<IconScale>,
        trackSizes: Set<TrackIconSize>,
        generateToolbar: Bool,
        generateTrack: Bool,
        normalAdjustment: HSBAdjustment,
        hoverAdjustment: HSBAdjustment,
        activeAdjustment: HSBAdjustment,
        padding: Double = 0,
        generateToggle: Bool = false,
        onNormalAdjustment: HSBAdjustment = .onNormal,
        onHoverAdjustment: HSBAdjustment = .onHover,
        onActiveAdjustment: HSBAdjustment = .onActive
    ) throws {
        let sanitizedName = sanitizeIconName(iconName)

        if generateToolbar && !toolbarScales.isEmpty {
            // Export OFF state icons
            try exportToolbarIcons(
                sourceImage: sourceImage,
                iconName: sanitizedName,
                destinationURL: destinationURL,
                scales: toolbarScales,
                normalAdjustment: normalAdjustment,
                hoverAdjustment: hoverAdjustment,
                activeAdjustment: activeAdjustment,
                padding: padding
            )

            // Export ON state icons if toggle is enabled
            if generateToggle {
                try exportToolbarIcons(
                    sourceImage: sourceImage,
                    iconName: sanitizedName + "_on",
                    destinationURL: destinationURL,
                    scales: toolbarScales,
                    normalAdjustment: onNormalAdjustment,
                    hoverAdjustment: onHoverAdjustment,
                    activeAdjustment: onActiveAdjustment,
                    padding: padding
                )
            }
        }

        if generateTrack && !trackSizes.isEmpty {
            try exportTrackIcons(
                sourceImage: sourceImage,
                iconName: sanitizedName,
                destinationURL: destinationURL,
                sizes: trackSizes
            )
        }
    }

    // MARK: - Manual Mode Export

    func exportToFolderManual(
        normalImage: NSImage,
        hoverImage: NSImage,
        activeImage: NSImage,
        iconName: String,
        destinationURL: URL,
        toolbarScales: Set<IconScale>,
        trackSizes: Set<TrackIconSize>,
        generateToolbar: Bool,
        generateTrack: Bool,
        padding: Double = 0,
        generateToggle: Bool = false,
        onNormalImage: NSImage? = nil,
        onHoverImage: NSImage? = nil,
        onActiveImage: NSImage? = nil
    ) throws {
        let sanitizedName = sanitizeIconName(iconName)

        if generateToolbar && !toolbarScales.isEmpty {
            // Export OFF state icons
            try exportToolbarIconsManual(
                normalImage: normalImage,
                hoverImage: hoverImage,
                activeImage: activeImage,
                iconName: sanitizedName,
                destinationURL: destinationURL,
                scales: toolbarScales,
                padding: padding
            )

            // Export ON state icons if toggle is enabled
            if generateToggle,
               let onNormal = onNormalImage,
               let onHover = onHoverImage,
               let onActive = onActiveImage {
                try exportToolbarIconsManual(
                    normalImage: onNormal,
                    hoverImage: onHover,
                    activeImage: onActive,
                    iconName: sanitizedName + "_on",
                    destinationURL: destinationURL,
                    scales: toolbarScales,
                    padding: padding
                )
            }
        }

        if generateTrack && !trackSizes.isEmpty {
            try exportTrackIcons(
                sourceImage: normalImage,
                iconName: sanitizedName,
                destinationURL: destinationURL,
                sizes: trackSizes
            )
        }
    }

    // MARK: - Private Toolbar Export

    private func exportToolbarIcons(
        sourceImage: NSImage,
        iconName: String,
        destinationURL: URL,
        scales: Set<IconScale>,
        normalAdjustment: HSBAdjustment,
        hoverAdjustment: HSBAdjustment,
        activeAdjustment: HSBAdjustment,
        padding: Double
    ) throws {
        let toolbarPath = destinationURL.appendingPathComponent("toolbar_icons")

        for scale in scales.sorted(by: { $0.rawValue < $1.rawValue }) {
            var targetPath = toolbarPath

            if let folderName = scale.folderName {
                targetPath = toolbarPath.appendingPathComponent(folderName)
            }

            try createDirectoryIfNeeded(at: targetPath)

            let icon = processor.generateToolbarIcon(
                from: sourceImage,
                scale: scale,
                normalAdjustment: normalAdjustment,
                hoverAdjustment: hoverAdjustment,
                activeAdjustment: activeAdjustment,
                padding: padding
            )

            let filePath = targetPath.appendingPathComponent("\(iconName).png")
            try saveImage(icon, to: filePath)
        }
    }

    private func exportToolbarIconsManual(
        normalImage: NSImage,
        hoverImage: NSImage,
        activeImage: NSImage,
        iconName: String,
        destinationURL: URL,
        scales: Set<IconScale>,
        padding: Double
    ) throws {
        let toolbarPath = destinationURL.appendingPathComponent("toolbar_icons")

        for scale in scales.sorted(by: { $0.rawValue < $1.rawValue }) {
            var targetPath = toolbarPath

            if let folderName = scale.folderName {
                targetPath = toolbarPath.appendingPathComponent(folderName)
            }

            try createDirectoryIfNeeded(at: targetPath)

            let icon = processor.generateToolbarIconManual(
                normalImage: normalImage,
                hoverImage: hoverImage,
                activeImage: activeImage,
                scale: scale,
                padding: padding
            )

            let filePath = targetPath.appendingPathComponent("\(iconName).png")
            try saveImage(icon, to: filePath)
        }
    }

    private func exportTrackIcons(
        sourceImage: NSImage,
        iconName: String,
        destinationURL: URL,
        sizes: Set<TrackIconSize>
    ) throws {
        let trackPath = destinationURL.appendingPathComponent("track_icons")
        try createDirectoryIfNeeded(at: trackPath)

        for size in sizes.sorted(by: { $0.rawValue < $1.rawValue }) {
            let icon = processor.generateTrackIcon(from: sourceImage, size: size)

            let fileName: String
            if sizes.count > 1 {
                fileName = "\(iconName)_\(size.rawValue).png"
            } else {
                fileName = "\(iconName).png"
            }

            let filePath = trackPath.appendingPathComponent(fileName)
            try saveImage(icon, to: filePath)
        }
    }

    private func createDirectoryIfNeeded(at url: URL) throws {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
            } catch {
                throw ExportError.createDirectoryFailed(url.path)
            }
        }
    }

    private func saveImage(_ image: NSImage, to url: URL) throws {
        // Create bitmap at exact pixel dimensions (not Retina scaled)
        let width = Int(image.size.width)
        let height = Int(image.size.height)

        guard let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            throw ExportError.saveFailed(url.path)
        }

        bitmapRep.size = image.size

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
        NSGraphicsContext.current?.imageInterpolation = .high

        image.draw(
            in: NSRect(x: 0, y: 0, width: width, height: height),
            from: NSRect(origin: .zero, size: image.size),
            operation: .copy,
            fraction: 1.0
        )

        NSGraphicsContext.restoreGraphicsState()

        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            throw ExportError.saveFailed(url.path)
        }

        do {
            try pngData.write(to: url)
        } catch {
            throw ExportError.saveFailed(url.path)
        }
    }

    private func sanitizeIconName(_ name: String) -> String {
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-"))
        let sanitized = name.unicodeScalars.filter { allowedCharacters.contains($0) }
        let result = String(String.UnicodeScalarView(sanitized))
        return result.isEmpty ? "icon" : result
    }
}
