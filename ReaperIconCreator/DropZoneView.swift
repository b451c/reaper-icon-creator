import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct DropZoneView: View {
    @Binding var image: NSImage?
    @State private var isTargeted = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 2, dash: [8])
                )
                .foregroundColor(isTargeted ? .accentColor : .secondary.opacity(0.5))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isTargeted ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.05))
                )

            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(20)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("Drop Image Here")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("or click to browse")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("PNG, JPG, WEBP, TIFF, BMP, GIF")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
        }
        .frame(minHeight: 200)
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
            provider.loadItem(forTypeIdentifier: UTType.image.identifier) { item, error in
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
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, error in
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
        panel.allowedContentTypes = [
            .png, .jpeg, .webP, .tiff, .bmp, .gif,
            UTType(filenameExtension: "webp") ?? .image
        ]

        if panel.runModal() == .OK, let url = panel.url {
            loadImage(from: url)
        }
    }
}

struct DropZoneView_Previews: PreviewProvider {
    static var previews: some View {
        DropZoneView(image: .constant(nil))
            .frame(width: 400, height: 250)
            .padding()
    }
}
