# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**oxiproimport** is a SwiftUI-based multi-platform application that imports blood pressure data from OxiPro BP2 CSV files into Apple Health. The app bypasses subscription requirements by providing a free alternative to save health data.

## Key Project Configuration

- **Bundle Identifier**: `mobi.bouncingball.oxiproimport`
- **Development Team**: EE24DSWS8T
- **Deployment Targets**: 
  - iOS 26.0
  - macOS 26.0
  - visionOS 26.0
- **Swift Version**: 5.0
- **Supported Platforms**: iPhone, iPad, Mac, Vision Pro
- **Security Settings**:
  - App Sandbox: Enabled
  - Hardened Runtime: Enabled
  - User Selected Files: Read-only access

## Build Commands

### Building the project
```bash
# Build for iOS Simulator
xcodebuild -project oxiproimport.xcodeproj -scheme oxiproimport -destination 'platform=iOS Simulator,name=iPhone 16' build

# Build for macOS
xcodebuild -project oxiproimport.xcodeproj -scheme oxiproimport -destination 'platform=macOS' build

# Build for release
xcodebuild -project oxiproimport.xcodeproj -scheme oxiproimport -configuration Release build
```

### Running the project
```bash
# Open in Xcode
open oxiproimport.xcodeproj

# Run on iOS Simulator
xcodebuild -project oxiproimport.xcodeproj -scheme oxiproimport -destination 'platform=iOS Simulator,name=iPhone 16' run

# Run on macOS
xcodebuild -project oxiproimport.xcodeproj -scheme oxiproimport -destination 'platform=macOS' run
```

### Testing
```bash
# Run unit tests
xcodebuild test -project oxiproimport.xcodeproj -scheme oxiproimport -destination 'platform=iOS Simulator,name=iPhone 16'

# Run UI tests
xcodebuild test -project oxiproimport.xcodeproj -scheme oxiproimport -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:oxiproimportUITests
```

### Linting and Code Quality
```bash
# Format Swift code using swift-format (if installed)
swift-format -i -r oxiproimport/

# Lint with SwiftLint (if integrated)
swiftlint --path oxiproimport/
```

## Code Architecture

### Project Structure
```
oxiproimport/
├── oxiproimport.xcodeproj/     # Xcode project configuration
├── oxiproimport/               # Main application source code
│   ├── oxiproimportApp.swift   # App entry point (@main)
│   ├── ContentView.swift       # Main UI view
│   └── Assets.xcassets/        # App icons, colors, and image assets
```

### Core Components

1. **oxiproimportApp.swift**: The app's entry point using SwiftUI's App protocol. Handles incoming CSV files from share sheet via `IncomingFileHandler`.

2. **ContentView.swift**: The main view providing file import functionality, HealthKit authorization, and import preview.

3. **Models/**:
   - `BloodPressureReading.swift`: Data model for blood pressure readings with CSV parsing support
   - `ImportHistory.swift`: Tracks import history with persistence

4. **Services/**:
   - `CSVParser.swift`: Parses OxiPro BP2 CSV files into structured data
   - `HealthKitManager.swift`: Manages HealthKit authorization and data writing

5. **Views/**:
   - `HealthKitAuthorizationView.swift`: Guides users through HealthKit permissions
   - `ImportPreviewView.swift`: Shows parsed data before importing to Health
   - `ImportHistoryView.swift`: Displays previous import history

### Architecture Notes

- The project uses SwiftUI's declarative UI framework
- Follows Apple's recommended app structure with @main entry point
- Uses WindowGroup for multi-window support on macOS and iPad
- Preview support is enabled for SwiftUI development
- No external dependencies or Swift Package Manager packages are currently integrated

### Development Workflow

When adding new features:
1. Create new SwiftUI views in separate files within the oxiproimport/ directory
2. Follow SwiftUI naming conventions (views end with "View")
3. Use @State, @StateObject, @ObservedObject for state management
4. Leverage SwiftUI previews for rapid development
5. Test on multiple platforms given the multi-platform support

### Important Considerations

- The project targets very recent OS versions (26.0), which are future versions
- App Sandbox is enabled, limiting file system and network access
- Hardened Runtime is enabled for macOS, requiring entitlements for certain operations
- File access is limited to read-only for user-selected files
- HealthKit capability must be added in Xcode project settings
- Info.plist requires specific entries for CSV file handling and HealthKit permissions
- **File Access**: Uses security-scoped resources for file access from share sheet and document picker
- **HealthKit Authorization**: Only requests individual data types (systolic, diastolic, heart rate) not correlation types

### CSV File Format

The app expects CSV files from OxiPro BP2 with the following columns:
- Date (YYYY-MM-DD format)
- Time (HH:MM format)
- Sys (Systolic blood pressure)
- Dia (Diastolic blood pressure)
- Pulse (Heart rate, optional)
- Irregular pulse (detected/not detected)
- Source (Device name)

### HealthKit Integration

The app writes the following data types to HealthKit:
- Blood Pressure (correlated systolic and diastolic values)
- Heart Rate (if present in CSV)
- Metadata includes source device and import timestamp