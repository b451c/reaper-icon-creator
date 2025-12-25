# REAPER Icon Creator

A native macOS application for creating REAPER-compatible toolbar and track icons with automatic state generation, toggle ON/OFF support, and live preview.

![macOS](https://img.shields.io/badge/macOS-12.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-4.0-purple)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **Two Generation Modes**
  - **Automatic**: Generate Normal, Hover, and Active states from a single image using HSB adjustments
  - **Manual**: Provide separate images for each state with drag & drop between slots

- **Toggle ON/OFF Icons**
  - Generate both `icon.png` (OFF state) and `icon_on.png` (ON state)
  - Separate HSB adjustments or images for ON states
  - Full REAPER toggle button support

- **Interactive Toolbar Simulator**
  - Live preview in the corner showing how icons will look in REAPER
  - Hover and click simulation
  - Toggle state preview for ON/OFF icons

- **Flexible Output**
  - **Toolbar icons**: 3 scales (100%, 150%, 200%)
  - **Track icons**: 3 sizes (64px, 128px, 256px)
  - Adjustable padding for icon margins

- **REAPER Integration**
  - Direct export to REAPER's Data folder
  - Automatic folder structure creation
  - Proper file naming conventions

## System Requirements

- macOS 12.0 (Monterey) or later
- Apple Silicon or Intel Mac

## Installation

### Download Release
1. Download the latest `.zip` from [Releases](https://github.com/b451c/reaper-icon-creator/releases)
2. Extract and move `ReaperIconCreator.app` to Applications
3. On first launch, right-click and select "Open" to bypass Gatekeeper

### Build from Source
1. Clone the repository:
   ```bash
   git clone https://github.com/b451c/reaper-icon-creator.git
   ```
2. Open `ReaperIconCreator.xcodeproj` in Xcode 15+
3. Select your development team in Signing & Capabilities
4. Build and run (Cmd+R)

## Usage

### Automatic Mode (Default)

1. **Drop an image** onto the drop zone or click to browse
2. **Adjust HSB sliders** for each state (Normal, Hover, Active)
3. **Enable Toggle Icon** if you need ON/OFF states
4. **Select scales/sizes** for toolbar and track icons
5. **Export** to folder or directly to REAPER

### Manual Mode

1. Switch to **Manual** mode in the State Image Mode picker
2. **Drop separate images** for Normal, Hover, and Active states
3. **Drag between slots** to rearrange (swap within same section, copy between OFF/ON)
4. **Click to select**, press Delete to remove
5. For toggle icons, provide all 6 images (3 OFF + 3 ON states)

### Toggle Icons

REAPER toggle buttons use two icon files:
- `iconname.png` - displayed when toggle is OFF
- `iconname_on.png` - displayed when toggle is ON

Each file contains 3 states arranged horizontally. When assigning in REAPER, select only the base icon name - REAPER finds the `_on` variant automatically.

**Important**: The action must be registered as a toggle in REAPER for the ON state to work.

## Toolbar Icon Specification

REAPER toolbar icons are horizontal strips containing 3 button states:

```
┌──────────┬──────────┬──────────┐
│  Normal  │  Hover   │  Active  │
└──────────┴──────────┴──────────┘
```

### Sizes

| Scale | State Size | Total Size |
|-------|------------|------------|
| 100%  | 30×30 px   | 90×30 px   |
| 150%  | 45×45 px   | 135×45 px  |
| 200%  | 60×60 px   | 180×60 px  |

### Default HSB Adjustments

**OFF States:**
| State  | Hue | Saturation | Brightness |
|--------|-----|------------|------------|
| Normal | 0%  | 0%         | -10%       |
| Hover  | 0%  | 0%         | +15%       |
| Active | 0%  | -20%       | -25%       |

**ON States:**
| State  | Hue | Saturation | Brightness |
|--------|-----|------------|------------|
| Normal | 0%  | +15%       | +10%       |
| Hover  | 0%  | +15%       | +25%       |
| Active | 0%  | 0%         | -10%       |

## Export Structure

```
[destination]/
├── toolbar_icons/
│   ├── iconname.png           # 100% scale (OFF state)
│   ├── iconname_on.png        # 100% scale (ON state, if toggle enabled)
│   ├── 150/
│   │   ├── iconname.png       # 150% scale
│   │   └── iconname_on.png
│   └── 200/
│       ├── iconname.png       # 200% scale
│       └── iconname_on.png
└── track_icons/
    └── iconname.png           # Track icon
```

## REAPER Integration

### Toolbar Icons
1. Export icons to REAPER's Data folder (or copy manually)
2. Open REAPER → Right-click any toolbar → "Customize toolbar..."
3. Click "Add" and find your icon
4. Assign to an action
5. For toggle icons, ensure the action is toggle-capable

### Track Icons
1. Right-click a track's icon area
2. Select "Load track icon..."
3. Navigate to `track_icons` folder

## Supported Image Formats

- PNG (recommended)
- JPEG
- WEBP
- TIFF
- BMP
- GIF

Non-square images are automatically cropped to center-square.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Credits

Built with SwiftUI for macOS.

REAPER is a trademark of Cockos Incorporated.

---

**Made for REAPER users who need custom toolbar icons.**
