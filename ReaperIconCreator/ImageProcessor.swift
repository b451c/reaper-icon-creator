import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins

class ImageProcessor {
    static let shared = ImageProcessor()
    private let context = CIContext()

    private init() {}

    func cropToSquare(_ image: NSImage) -> NSImage {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return image
        }

        let width = cgImage.width
        let height = cgImage.height
        let size = min(width, height)

        let x = (width - size) / 2
        let y = (height - size) / 2

        let cropRect = CGRect(x: x, y: y, width: size, height: size)

        guard let croppedCGImage = cgImage.cropping(to: cropRect) else {
            return image
        }

        return NSImage(cgImage: croppedCGImage, size: NSSize(width: size, height: size))
    }

    func scaleImage(_ image: NSImage, to size: NSSize) -> NSImage {
        // Use exact pixel dimensions (not Retina scaled)
        let width = Int(size.width)
        let height = Int(size.height)

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
            return image
        }

        bitmapRep.size = size

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
        NSGraphicsContext.current?.imageInterpolation = .high

        image.draw(
            in: NSRect(origin: .zero, size: size),
            from: NSRect(origin: .zero, size: image.size),
            operation: .copy,
            fraction: 1.0
        )

        NSGraphicsContext.restoreGraphicsState()

        let newImage = NSImage(size: size)
        newImage.addRepresentation(bitmapRep)
        return newImage
    }

    func scaleImageWithPadding(_ image: NSImage, to size: NSSize, padding: Double) -> NSImage {
        // Use exact pixel dimensions (not Retina scaled)
        let width = Int(size.width)
        let height = Int(size.height)

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
            return image
        }

        bitmapRep.size = size

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
        NSGraphicsContext.current?.imageInterpolation = .high

        // Clear with transparent background
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()

        // Calculate inner size after padding
        let paddingPixels = size.width * padding
        let innerSize = NSSize(
            width: size.width - (paddingPixels * 2),
            height: size.height - (paddingPixels * 2)
        )
        let origin = NSPoint(x: paddingPixels, y: paddingPixels)

        image.draw(
            in: NSRect(origin: origin, size: innerSize),
            from: NSRect(origin: .zero, size: image.size),
            operation: .sourceOver,
            fraction: 1.0
        )

        NSGraphicsContext.restoreGraphicsState()

        let newImage = NSImage(size: size)
        newImage.addRepresentation(bitmapRep)
        return newImage
    }

    func adjustHSB(_ image: NSImage, adjustment: HSBAdjustment) -> NSImage {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return image
        }

        let ciImage = CIImage(cgImage: cgImage)

        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = ciImage
        colorControls.saturation = Float(1.0 + adjustment.saturation)
        colorControls.brightness = Float(adjustment.brightness)
        colorControls.contrast = 1.0

        guard let colorControlsOutput = colorControls.outputImage else {
            return image
        }

        let hueAdjust = CIFilter.hueAdjust()
        hueAdjust.inputImage = colorControlsOutput
        hueAdjust.angle = Float(adjustment.hue * .pi)

        guard let outputCIImage = hueAdjust.outputImage,
              let outputCGImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) else {
            return image
        }

        return NSImage(cgImage: outputCGImage, size: image.size)
    }

    func combineStates(normal: NSImage, hover: NSImage, active: NSImage, stateSize: Int) -> NSImage {
        let size = CGFloat(stateSize)
        let totalSize = NSSize(width: size * 3, height: size)
        let width = Int(totalSize.width)
        let height = Int(totalSize.height)

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
            return normal
        }

        bitmapRep.size = totalSize

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
        NSGraphicsContext.current?.imageInterpolation = .high

        normal.draw(
            in: NSRect(x: 0, y: 0, width: size, height: size),
            from: NSRect(origin: .zero, size: normal.size),
            operation: .copy,
            fraction: 1.0
        )

        hover.draw(
            in: NSRect(x: size, y: 0, width: size, height: size),
            from: NSRect(origin: .zero, size: hover.size),
            operation: .copy,
            fraction: 1.0
        )

        active.draw(
            in: NSRect(x: size * 2, y: 0, width: size, height: size),
            from: NSRect(origin: .zero, size: active.size),
            operation: .copy,
            fraction: 1.0
        )

        NSGraphicsContext.restoreGraphicsState()

        let combinedImage = NSImage(size: totalSize)
        combinedImage.addRepresentation(bitmapRep)
        return combinedImage
    }

    func generateToolbarIcon(
        from sourceImage: NSImage,
        scale: IconScale,
        normalAdjustment: HSBAdjustment,
        hoverAdjustment: HSBAdjustment,
        activeAdjustment: HSBAdjustment,
        padding: Double = 0
    ) -> NSImage {
        let squared = cropToSquare(sourceImage)
        let stateSize = NSSize(width: CGFloat(scale.stateSize), height: CGFloat(scale.stateSize))

        let normal: NSImage
        let hover: NSImage
        let active: NSImage

        if padding > 0 {
            normal = scaleImageWithPadding(adjustHSB(squared, adjustment: normalAdjustment), to: stateSize, padding: padding)
            hover = scaleImageWithPadding(adjustHSB(squared, adjustment: hoverAdjustment), to: stateSize, padding: padding)
            active = scaleImageWithPadding(adjustHSB(squared, adjustment: activeAdjustment), to: stateSize, padding: padding)
        } else {
            normal = adjustHSB(scaleImage(squared, to: stateSize), adjustment: normalAdjustment)
            hover = adjustHSB(scaleImage(squared, to: stateSize), adjustment: hoverAdjustment)
            active = adjustHSB(scaleImage(squared, to: stateSize), adjustment: activeAdjustment)
        }

        return combineStates(normal: normal, hover: hover, active: active, stateSize: scale.stateSize)
    }

    func generateToolbarIconManual(
        normalImage: NSImage,
        hoverImage: NSImage,
        activeImage: NSImage,
        scale: IconScale,
        padding: Double = 0
    ) -> NSImage {
        let stateSize = NSSize(width: CGFloat(scale.stateSize), height: CGFloat(scale.stateSize))

        let normalSquared = cropToSquare(normalImage)
        let hoverSquared = cropToSquare(hoverImage)
        let activeSquared = cropToSquare(activeImage)

        let normal: NSImage
        let hover: NSImage
        let active: NSImage

        if padding > 0 {
            normal = scaleImageWithPadding(normalSquared, to: stateSize, padding: padding)
            hover = scaleImageWithPadding(hoverSquared, to: stateSize, padding: padding)
            active = scaleImageWithPadding(activeSquared, to: stateSize, padding: padding)
        } else {
            normal = scaleImage(normalSquared, to: stateSize)
            hover = scaleImage(hoverSquared, to: stateSize)
            active = scaleImage(activeSquared, to: stateSize)
        }

        return combineStates(normal: normal, hover: hover, active: active, stateSize: scale.stateSize)
    }

    func generateTrackIcon(from sourceImage: NSImage, size: TrackIconSize) -> NSImage {
        let squared = cropToSquare(sourceImage)
        let targetSize = NSSize(width: CGFloat(size.rawValue), height: CGFloat(size.rawValue))
        return scaleImage(squared, to: targetSize)
    }

    func generateStatePreview(
        from sourceImage: NSImage,
        adjustment: HSBAdjustment,
        size: Int
    ) -> NSImage {
        let squared = cropToSquare(sourceImage)
        let targetSize = NSSize(width: CGFloat(size), height: CGFloat(size))
        let scaled = scaleImage(squared, to: targetSize)
        return adjustHSB(scaled, adjustment: adjustment)
    }
}
