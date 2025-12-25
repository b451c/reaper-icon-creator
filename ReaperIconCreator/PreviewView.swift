import SwiftUI
import AppKit

struct ToolbarIconPreview: View {
    let sourceImage: NSImage?
    let scale: IconScale
    let normalAdjustment: HSBAdjustment
    let hoverAdjustment: HSBAdjustment
    let activeAdjustment: HSBAdjustment
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

            if let source = sourceImage {
                let toolbarIcon = processor.generateToolbarIcon(
                    from: source,
                    scale: scale,
                    normalAdjustment: normalAdjustment,
                    hoverAdjustment: hoverAdjustment,
                    activeAdjustment: activeAdjustment,
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
                Text("No image")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .opacity(isSelected ? 1.0 : 0.5)
    }
}

struct TrackIconPreview: View {
    let sourceImage: NSImage?
    let size: TrackIconSize
    let isSelected: Bool
    let onToggle: () -> Void

    private let processor = ImageProcessor.shared

    var body: some View {
        VStack(spacing: 8) {
            Toggle(isOn: Binding(get: { isSelected }, set: { _ in onToggle() })) {
                Text(size.displayName)
                    .font(.system(.body, design: .monospaced))
            }
            .toggleStyle(.checkbox)

            if let source = sourceImage {
                let trackIcon = processor.generateTrackIcon(from: source, size: size)

                ZStack {
                    CheckerboardBackground()
                        .frame(width: CGFloat(size.rawValue), height: CGFloat(size.rawValue))
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    Image(nsImage: trackIcon)
                        .interpolation(.high)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                )
                .frame(maxWidth: 100, maxHeight: 100)
                .scaleEffect(size.rawValue > 100 ? 100.0 / CGFloat(size.rawValue) : 1.0)
            }
        }
        .opacity(isSelected ? 1.0 : 0.5)
    }
}

struct StatePreviewRow: View {
    let sourceImage: NSImage?
    let normalAdjustment: HSBAdjustment
    let hoverAdjustment: HSBAdjustment
    let activeAdjustment: HSBAdjustment

    private let processor = ImageProcessor.shared
    private let previewSize = 60

    var body: some View {
        HStack(spacing: 20) {
            statePreview(title: "Normal", adjustment: normalAdjustment)
            statePreview(title: "Hover", adjustment: hoverAdjustment)
            statePreview(title: "Active", adjustment: activeAdjustment)
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func statePreview(title: String, adjustment: HSBAdjustment) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            if let source = sourceImage {
                let preview = processor.generateStatePreview(
                    from: source,
                    adjustment: adjustment,
                    size: previewSize
                )

                ZStack {
                    CheckerboardBackground()
                        .frame(width: CGFloat(previewSize), height: CGFloat(previewSize))
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    Image(nsImage: preview)
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
            }
        }
    }
}

struct CheckerboardBackground: View {
    let squareSize: CGFloat = 8

    var body: some View {
        Canvas { context, size in
            let rows = Int(ceil(size.height / squareSize))
            let cols = Int(ceil(size.width / squareSize))

            for row in 0..<rows {
                for col in 0..<cols {
                    let isLight = (row + col) % 2 == 0
                    let rect = CGRect(
                        x: CGFloat(col) * squareSize,
                        y: CGFloat(row) * squareSize,
                        width: squareSize,
                        height: squareSize
                    )
                    context.fill(
                        Path(rect),
                        with: .color(isLight ? Color.white : Color.gray.opacity(0.3))
                    )
                }
            }
        }
    }
}

struct PreviewView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ToolbarIconPreview(
                sourceImage: nil,
                scale: .scale100,
                normalAdjustment: .normal,
                hoverAdjustment: .hover,
                activeAdjustment: .active,
                isSelected: true,
                onToggle: {}
            )
        }
        .padding()
    }
}
