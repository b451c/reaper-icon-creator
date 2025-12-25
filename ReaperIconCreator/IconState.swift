import SwiftUI
import AppKit

struct HSBAdjustment: Equatable {
    var hue: Double = 0
    var saturation: Double = 0
    var brightness: Double = 0

    static let normal = HSBAdjustment(hue: 0, saturation: 0, brightness: -0.10)
    static let hover = HSBAdjustment(hue: 0, saturation: 0, brightness: 0.15)
    static let active = HSBAdjustment(hue: 0, saturation: -0.20, brightness: -0.25)

    // ON state defaults (brighter/more saturated to indicate active toggle)
    static let onNormal = HSBAdjustment(hue: 0, saturation: 0.15, brightness: 0.10)
    static let onHover = HSBAdjustment(hue: 0, saturation: 0.15, brightness: 0.25)
    static let onActive = HSBAdjustment(hue: 0, saturation: 0, brightness: -0.10)
}

enum IconScale: Int, CaseIterable, Identifiable {
    case scale100 = 100
    case scale150 = 150
    case scale200 = 200

    var id: Int { rawValue }

    var stateSize: Int {
        switch self {
        case .scale100: return 30
        case .scale150: return 45
        case .scale200: return 60
        }
    }

    var totalSize: NSSize {
        let state = CGFloat(stateSize)
        return NSSize(width: state * 3, height: state)
    }

    var displayName: String {
        "\(rawValue)%"
    }

    var folderName: String? {
        switch self {
        case .scale100: return nil
        case .scale150: return "150"
        case .scale200: return "200"
        }
    }
}

enum TrackIconSize: Int, CaseIterable, Identifiable {
    case size64 = 64
    case size128 = 128
    case size256 = 256

    var id: Int { rawValue }

    var displayName: String {
        "\(rawValue)px"
    }
}

enum StateImageMode: String, CaseIterable {
    case automatic = "Auto (HSB)"
    case manual = "Manual"
}

enum ManualSlotID: String, CaseIterable {
    case offNormal = "off_normal"
    case offHover = "off_hover"
    case offActive = "off_active"
    case onNormal = "on_normal"
    case onHover = "on_hover"
    case onActive = "on_active"
}

class IconCreatorState: ObservableObject {
    @Published var sourceImage: NSImage?
    @Published var iconName: String = "my_icon"

    // State image mode
    @Published var stateImageMode: StateImageMode = .automatic

    // Manual state images (OFF state)
    @Published var normalStateImage: NSImage?
    @Published var hoverStateImage: NSImage?
    @Published var activeStateImage: NSImage?

    // HSB adjustments for OFF state (automatic mode)
    @Published var normalAdjustment = HSBAdjustment.normal
    @Published var hoverAdjustment = HSBAdjustment.hover
    @Published var activeAdjustment = HSBAdjustment.active

    // Toggle ON/OFF support
    @Published var generateToggleIcon = false

    // HSB adjustments for ON state (automatic mode)
    @Published var onNormalAdjustment = HSBAdjustment.onNormal
    @Published var onHoverAdjustment = HSBAdjustment.onHover
    @Published var onActiveAdjustment = HSBAdjustment.onActive

    // Manual state images (ON state)
    @Published var onNormalStateImage: NSImage?
    @Published var onHoverStateImage: NSImage?
    @Published var onActiveStateImage: NSImage?

    // Icon padding (percentage of total size as margin)
    @Published var iconPadding: Double = 0  // No padding by default

    @Published var selectedToolbarScales: Set<IconScale> = Set(IconScale.allCases)
    @Published var selectedTrackSizes: Set<TrackIconSize> = [.size128]

    @Published var generateToolbarIcons = true
    @Published var generateTrackIcons = true

    @Published var reaperPath: URL? = IconCreatorState.defaultReaperPath()

    @Published var isExporting = false
    @Published var exportError: String?
    @Published var exportSuccess = false

    // Selection for manual mode drag & drop
    @Published var selectedSlot: ManualSlotID?

    static func defaultReaperPath() -> URL? {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let reaperPath = home.appendingPathComponent("Library/Application Support/REAPER")
        if FileManager.default.fileExists(atPath: reaperPath.path) {
            return reaperPath
        }
        return nil
    }

    var hasValidImage: Bool {
        sourceImage != nil
    }

    var hasValidManualStates: Bool {
        let hasOffStates = normalStateImage != nil && hoverStateImage != nil && activeStateImage != nil
        if generateToggleIcon {
            let hasOnStates = onNormalStateImage != nil && onHoverStateImage != nil && onActiveStateImage != nil
            return hasOffStates && hasOnStates
        }
        return hasOffStates
    }

    var canExport: Bool {
        let hasImages = stateImageMode == .automatic ? hasValidImage : hasValidManualStates
        return hasImages && !iconName.isEmpty && (generateToolbarIcons || generateTrackIcons)
    }

    // Get effective images for each state
    func effectiveNormalImage() -> NSImage? {
        stateImageMode == .manual ? normalStateImage : sourceImage
    }

    func effectiveHoverImage() -> NSImage? {
        stateImageMode == .manual ? hoverStateImage : sourceImage
    }

    func effectiveActiveImage() -> NSImage? {
        stateImageMode == .manual ? activeStateImage : sourceImage
    }

    // MARK: - Slot Access Methods

    func image(for slot: ManualSlotID) -> NSImage? {
        switch slot {
        case .offNormal: return normalStateImage
        case .offHover: return hoverStateImage
        case .offActive: return activeStateImage
        case .onNormal: return onNormalStateImage
        case .onHover: return onHoverStateImage
        case .onActive: return onActiveStateImage
        }
    }

    func setImage(_ image: NSImage?, for slot: ManualSlotID) {
        switch slot {
        case .offNormal: normalStateImage = image
        case .offHover: hoverStateImage = image
        case .offActive: activeStateImage = image
        case .onNormal: onNormalStateImage = image
        case .onHover: onHoverStateImage = image
        case .onActive: onActiveStateImage = image
        }
    }

    func moveImage(from source: ManualSlotID, to destination: ManualSlotID) {
        let sourceImage = image(for: source)

        // Check if both slots are in the same section
        let sourceIsOff = [ManualSlotID.offNormal, .offHover, .offActive].contains(source)
        let destIsOff = [ManualSlotID.offNormal, .offHover, .offActive].contains(destination)

        if sourceIsOff == destIsOff {
            // Same section - swap images
            let destImage = image(for: destination)
            setImage(destImage, for: source)
            setImage(sourceImage, for: destination)
        } else {
            // Different sections - copy image (don't remove from source)
            setImage(sourceImage, for: destination)
        }
    }

    func deleteSelectedImage() {
        guard let slot = selectedSlot else { return }
        setImage(nil, for: slot)
        selectedSlot = nil
    }
}
