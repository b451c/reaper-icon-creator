import SwiftUI
import AppKit

struct ToolbarSimulator: View {
    let offNormalImage: NSImage?
    let offHoverImage: NSImage?
    let offActiveImage: NSImage?
    let onNormalImage: NSImage?
    let onHoverImage: NSImage?
    let onActiveImage: NSImage?
    let isToggleIcon: Bool
    let scale: IconScale

    @State private var isToggled = false
    @State private var isHovering = false
    @State private var isPressed = false

    private let processor = ImageProcessor.shared

    var body: some View {
        VStack(spacing: 16) {
            // Simulator controls
            HStack {
                Text("Toolbar Simulator")
                    .font(.headline)

                Spacer()

                if isToggleIcon {
                    Text(isToggled ? "ON" : "OFF")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(isToggled ? Color.green.opacity(0.3) : Color.gray.opacity(0.3))
                        .cornerRadius(4)
                }
            }

            // Simulated toolbar
            HStack(spacing: 0) {
                // Dark toolbar background
                simulatedButton
                    .frame(width: CGFloat(scale.stateSize), height: CGFloat(scale.stateSize))
            }
            .padding(8)
            .background(Color(nsColor: NSColor(calibratedWhite: 0.2, alpha: 1.0)))
            .cornerRadius(4)

            // Instructions
            Text(isToggleIcon
                 ? "Najedź myszką i kliknij, aby przełączyć ON/OFF"
                 : "Najedź myszką i kliknij, aby zobaczyć stany")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }

    @ViewBuilder
    private var simulatedButton: some View {
        let currentImage = getCurrentStateImage()

        if let image = currentImage {
            Image(nsImage: image)
                .interpolation(.high)
                .onHover { hovering in
                    isHovering = hovering
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            isPressed = true
                        }
                        .onEnded { _ in
                            isPressed = false
                            if isToggleIcon {
                                isToggled.toggle()
                            }
                        }
                )
                .animation(.easeInOut(duration: 0.1), value: isHovering)
                .animation(.easeInOut(duration: 0.05), value: isPressed)
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    Text("?")
                        .foregroundColor(.secondary)
                )
        }
    }

    private func getCurrentStateImage() -> NSImage? {
        let useOnState = isToggleIcon && isToggled

        if isPressed {
            return useOnState ? onActiveImage : offActiveImage
        } else if isHovering {
            return useOnState ? onHoverImage : offHoverImage
        } else {
            return useOnState ? onNormalImage : offNormalImage
        }
    }
}

// Automatic mode simulator - generates states from single image
struct ToolbarSimulatorAutomatic: View {
    let sourceImage: NSImage?
    let scale: IconScale
    let normalAdjustment: HSBAdjustment
    let hoverAdjustment: HSBAdjustment
    let activeAdjustment: HSBAdjustment
    let onNormalAdjustment: HSBAdjustment
    let onHoverAdjustment: HSBAdjustment
    let onActiveAdjustment: HSBAdjustment
    let isToggleIcon: Bool
    let padding: Double

    private let processor = ImageProcessor.shared

    var body: some View {
        if let source = sourceImage {
            let squared = processor.cropToSquare(source)
            let stateSize = NSSize(width: CGFloat(scale.stateSize), height: CGFloat(scale.stateSize))

            let offNormal = generateStateImage(squared, adjustment: normalAdjustment, size: stateSize)
            let offHover = generateStateImage(squared, adjustment: hoverAdjustment, size: stateSize)
            let offActive = generateStateImage(squared, adjustment: activeAdjustment, size: stateSize)

            let onNormal = generateStateImage(squared, adjustment: onNormalAdjustment, size: stateSize)
            let onHover = generateStateImage(squared, adjustment: onHoverAdjustment, size: stateSize)
            let onActive = generateStateImage(squared, adjustment: onActiveAdjustment, size: stateSize)

            ToolbarSimulator(
                offNormalImage: offNormal,
                offHoverImage: offHover,
                offActiveImage: offActive,
                onNormalImage: isToggleIcon ? onNormal : nil,
                onHoverImage: isToggleIcon ? onHover : nil,
                onActiveImage: isToggleIcon ? onActive : nil,
                isToggleIcon: isToggleIcon,
                scale: scale
            )
        } else {
            emptySimulator
        }
    }

    private func generateStateImage(_ source: NSImage, adjustment: HSBAdjustment, size: NSSize) -> NSImage {
        let adjusted = processor.adjustHSB(source, adjustment: adjustment)
        if padding > 0 {
            return processor.scaleImageWithPadding(adjusted, to: size, padding: padding)
        } else {
            return processor.scaleImage(adjusted, to: size)
        }
    }

    private var emptySimulator: some View {
        VStack(spacing: 16) {
            Text("Toolbar Simulator")
                .font(.headline)

            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: CGFloat(scale.stateSize), height: CGFloat(scale.stateSize))
                .overlay(
                    Text("Załaduj obraz")
                        .font(.caption)
                        .foregroundColor(.secondary)
                )
                .padding(8)
                .background(Color(nsColor: NSColor(calibratedWhite: 0.2, alpha: 1.0)))
                .cornerRadius(4)
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Compact Versions for Corner Display

struct ToolbarSimulatorCompact: View {
    let sourceImage: NSImage?
    let scale: IconScale
    let normalAdjustment: HSBAdjustment
    let hoverAdjustment: HSBAdjustment
    let activeAdjustment: HSBAdjustment
    let onNormalAdjustment: HSBAdjustment
    let onHoverAdjustment: HSBAdjustment
    let onActiveAdjustment: HSBAdjustment
    let isToggleIcon: Bool
    let padding: Double

    private let processor = ImageProcessor.shared

    var body: some View {
        if let source = sourceImage {
            let squared = processor.cropToSquare(source)
            let stateSize = NSSize(width: CGFloat(scale.stateSize), height: CGFloat(scale.stateSize))

            let offNormal = generateStateImage(squared, adjustment: normalAdjustment, size: stateSize)
            let offHover = generateStateImage(squared, adjustment: hoverAdjustment, size: stateSize)
            let offActive = generateStateImage(squared, adjustment: activeAdjustment, size: stateSize)

            let onNormal = generateStateImage(squared, adjustment: onNormalAdjustment, size: stateSize)
            let onHover = generateStateImage(squared, adjustment: onHoverAdjustment, size: stateSize)
            let onActive = generateStateImage(squared, adjustment: onActiveAdjustment, size: stateSize)

            CompactSimulatorButton(
                offNormalImage: offNormal,
                offHoverImage: offHover,
                offActiveImage: offActive,
                onNormalImage: isToggleIcon ? onNormal : nil,
                onHoverImage: isToggleIcon ? onHover : nil,
                onActiveImage: isToggleIcon ? onActive : nil,
                isToggleIcon: isToggleIcon,
                scale: scale
            )
        } else {
            emptyCompactSimulator
        }
    }

    private func generateStateImage(_ source: NSImage, adjustment: HSBAdjustment, size: NSSize) -> NSImage {
        let adjusted = processor.adjustHSB(source, adjustment: adjustment)
        if padding > 0 {
            return processor.scaleImageWithPadding(adjusted, to: size, padding: padding)
        } else {
            return processor.scaleImage(adjusted, to: size)
        }
    }

    private var emptyCompactSimulator: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: CGFloat(scale.stateSize), height: CGFloat(scale.stateSize))
            .overlay(
                Text("?")
                    .font(.caption)
                    .foregroundColor(.secondary)
            )
            .padding(4)
            .background(Color(nsColor: NSColor(calibratedWhite: 0.2, alpha: 1.0)))
            .cornerRadius(4)
    }
}

struct ToolbarSimulatorManualCompact: View {
    let normalImage: NSImage?
    let hoverImage: NSImage?
    let activeImage: NSImage?
    let onNormalImage: NSImage?
    let onHoverImage: NSImage?
    let onActiveImage: NSImage?
    let scale: IconScale
    let isToggleIcon: Bool
    let padding: Double

    private let processor = ImageProcessor.shared

    var body: some View {
        if let normal = normalImage, let hover = hoverImage, let active = activeImage {
            let stateSize = NSSize(width: CGFloat(scale.stateSize), height: CGFloat(scale.stateSize))

            let offNormal = prepareImage(normal, size: stateSize)
            let offHover = prepareImage(hover, size: stateSize)
            let offActive = prepareImage(active, size: stateSize)

            let onNormal = onNormalImage.map { prepareImage($0, size: stateSize) }
            let onHover = onHoverImage.map { prepareImage($0, size: stateSize) }
            let onActive = onActiveImage.map { prepareImage($0, size: stateSize) }

            CompactSimulatorButton(
                offNormalImage: offNormal,
                offHoverImage: offHover,
                offActiveImage: offActive,
                onNormalImage: onNormal,
                onHoverImage: onHover,
                onActiveImage: onActive,
                isToggleIcon: isToggleIcon && onNormal != nil,
                scale: scale
            )
        } else {
            emptyCompactSimulator
        }
    }

    private func prepareImage(_ source: NSImage, size: NSSize) -> NSImage {
        let squared = processor.cropToSquare(source)
        if padding > 0 {
            return processor.scaleImageWithPadding(squared, to: size, padding: padding)
        } else {
            return processor.scaleImage(squared, to: size)
        }
    }

    private var emptyCompactSimulator: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: CGFloat(scale.stateSize), height: CGFloat(scale.stateSize))
            .overlay(
                Text("?")
                    .font(.caption)
                    .foregroundColor(.secondary)
            )
            .padding(4)
            .background(Color(nsColor: NSColor(calibratedWhite: 0.2, alpha: 1.0)))
            .cornerRadius(4)
    }
}

struct CompactSimulatorButton: View {
    let offNormalImage: NSImage?
    let offHoverImage: NSImage?
    let offActiveImage: NSImage?
    let onNormalImage: NSImage?
    let onHoverImage: NSImage?
    let onActiveImage: NSImage?
    let isToggleIcon: Bool
    let scale: IconScale

    @State private var isToggled = false
    @State private var isHovering = false
    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 0) {
                simulatedButton
                    .frame(width: CGFloat(scale.stateSize), height: CGFloat(scale.stateSize))
            }
            .padding(4)
            .background(Color(nsColor: NSColor(calibratedWhite: 0.2, alpha: 1.0)))
            .cornerRadius(4)

            if isToggleIcon {
                Text(isToggled ? "ON" : "OFF")
                    .font(.system(size: 9))
                    .foregroundColor(isToggled ? .green : .secondary)
            }
        }
    }

    @ViewBuilder
    private var simulatedButton: some View {
        let currentImage = getCurrentStateImage()

        if let image = currentImage {
            Image(nsImage: image)
                .interpolation(.high)
                .onHover { hovering in
                    isHovering = hovering
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            isPressed = true
                        }
                        .onEnded { _ in
                            isPressed = false
                            if isToggleIcon {
                                isToggled.toggle()
                            }
                        }
                )
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    Text("?")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                )
        }
    }

    private func getCurrentStateImage() -> NSImage? {
        let useOnState = isToggleIcon && isToggled

        if isPressed {
            return useOnState ? onActiveImage : offActiveImage
        } else if isHovering {
            return useOnState ? onHoverImage : offHoverImage
        } else {
            return useOnState ? onNormalImage : offNormalImage
        }
    }
}

// Manual mode simulator
struct ToolbarSimulatorManual: View {
    let normalImage: NSImage?
    let hoverImage: NSImage?
    let activeImage: NSImage?
    let onNormalImage: NSImage?
    let onHoverImage: NSImage?
    let onActiveImage: NSImage?
    let scale: IconScale
    let isToggleIcon: Bool
    let padding: Double

    private let processor = ImageProcessor.shared

    var body: some View {
        if let normal = normalImage, let hover = hoverImage, let active = activeImage {
            let stateSize = NSSize(width: CGFloat(scale.stateSize), height: CGFloat(scale.stateSize))

            let offNormal = prepareImage(normal, size: stateSize)
            let offHover = prepareImage(hover, size: stateSize)
            let offActive = prepareImage(active, size: stateSize)

            let onNormal = onNormalImage.map { prepareImage($0, size: stateSize) }
            let onHover = onHoverImage.map { prepareImage($0, size: stateSize) }
            let onActive = onActiveImage.map { prepareImage($0, size: stateSize) }

            ToolbarSimulator(
                offNormalImage: offNormal,
                offHoverImage: offHover,
                offActiveImage: offActive,
                onNormalImage: onNormal,
                onHoverImage: onHover,
                onActiveImage: onActive,
                isToggleIcon: isToggleIcon && onNormal != nil,
                scale: scale
            )
        } else {
            emptySimulator
        }
    }

    private func prepareImage(_ source: NSImage, size: NSSize) -> NSImage {
        let squared = processor.cropToSquare(source)
        if padding > 0 {
            return processor.scaleImageWithPadding(squared, to: size, padding: padding)
        } else {
            return processor.scaleImage(squared, to: size)
        }
    }

    private var emptySimulator: some View {
        VStack(spacing: 16) {
            Text("Toolbar Simulator")
                .font(.headline)

            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: CGFloat(scale.stateSize), height: CGFloat(scale.stateSize))
                .overlay(
                    Text("Załaduj obrazy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                )
                .padding(8)
                .background(Color(nsColor: NSColor(calibratedWhite: 0.2, alpha: 1.0)))
                .cornerRadius(4)
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
}
