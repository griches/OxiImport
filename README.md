# OxiPro Import

A free SwiftUI app for importing blood pressure data from OxiPro BP2 CSV files directly into Apple Health, bypassing subscription requirements.

## Features

- **Free Alternative**: Import your blood pressure data without paying for subscriptions
- **Native Integration**: Seamlessly integrates with Apple Health
- **Multi-Platform**: Works on iPhone, iPad, Mac, and Vision Pro
- **Share Sheet Support**: Import CSV files directly from other apps
- **Import History**: Track your import history and view recent readings
- **Privacy First**: All data processing happens locally on your device

## How It Works

1. Export CSV files from your OxiPro BP2 blood pressure monitor using [Health Diary by MedM](https://apps.apple.com/gb/app/health-diary-by-medm/id929581952)
2. Share the CSV file to OxiPro Import or use the in-app file picker
3. Preview your readings before importing
4. Import directly to Apple Health with one tap

## Supported Data

The app imports the following health data from OxiPro BP2 CSV files:

- **Blood Pressure** (Systolic/Diastolic)
- **Heart Rate** (if available)
- **Irregular Rhythm Detection**
- **Date and Time** of each reading
- **Source Device** information

## Requirements

- iOS 26.0+ / macOS 26.0+ / visionOS 26.0+
- Apple Health app
- OxiPro BP2 blood pressure monitor (for CSV export)

## CSV Format

The app expects CSV files with the following columns:
- `Date` (YYYY-MM-DD format)
- `Time` (HH:MM format)
- `Sys` (Systolic blood pressure)
- `Dia` (Diastolic blood pressure)
- `Pulse` (Heart rate, optional)
- `Irregular pulse` (detected/not detected)
- `Source` (Device name)

## Installation

1. Clone this repository
2. Open `oxiproimport.xcodeproj` in Xcode
3. Build and run on your device

## Building

```bash
# Build for iOS Simulator
xcodebuild -project oxiproimport.xcodeproj -scheme oxiproimport -destination 'platform=iOS Simulator,name=iPhone 16' build

# Build for macOS
xcodebuild -project oxiproimport.xcodeproj -scheme oxiproimport -destination 'platform=macOS' build

# Run tests
xcodebuild test -project oxiproimport.xcodeproj -scheme oxiproimport -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Privacy & Security

- **Local Processing**: All CSV parsing and data processing happens locally on your device
- **No Network Requests**: The app doesn't send any data to external servers
- **Secure File Access**: Uses security-scoped resources for file access
- **HealthKit Integration**: Follows Apple's HealthKit privacy guidelines
- **Sandboxed**: App runs in a secure sandbox environment

## Architecture

### Core Components

- **Models**: Data structures for blood pressure readings and import history
- **Services**: CSV parsing and HealthKit integration
- **Views**: SwiftUI interface components
- **Multi-Platform**: Single codebase supporting iOS, macOS, and visionOS

### Key Files

- `ContentView.swift` - Main app interface
- `HealthKitManager.swift` - Apple Health integration
- `CSVParser.swift` - OxiPro BP2 CSV parsing
- `BloodPressureReading.swift` - Core data model
- `ImportHistory.swift` - Import tracking and persistence

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is open source. Feel free to use, modify, and distribute as needed.

## Version History

### v1.1 (2025-07-29)
- **Duplicate Detection**: Automatically detects and skips duplicate readings when importing
- **Visual Indicators**: Shows which readings are duplicates in the import preview
- **Import Statistics**: Displays count of new readings imported vs duplicates skipped
- **HealthKit Read Access**: Added read permissions to check for existing data
- **Improved User Experience**: Cleaner imports without duplicate entries

### v1.0 (2025-07-29)
- **Initial Release**: Core CSV import functionality
- **Apple Health Integration**: Direct import to HealthKit
- **Share Sheet Support**: Import files from any app
- **Multi-Platform**: Support for iPhone, iPad, Mac, and Vision Pro
- **Import History**: Track all your imports
- **BOM Support**: Handles CSV files with Byte Order Mark
- **Privacy-Focused**: All processing happens locally

## Disclaimer

This app is not affiliated with OxiPro or any blood pressure monitor manufacturer. Always consult with healthcare professionals regarding your blood pressure readings and health data.