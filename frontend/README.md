# Aegis Frontend

Full-stack orchestration for development.

## Quick Start

```bash
# Get dependencies
flutter pub get

# Run on Windows
flutter run -d windows

# Run on Android
flutter run -d android

# Run on Chrome (web)
flutter run -d chrome
```

## Project Structure

```
lib/
├── core/                  # Theme, constants, utilities
│   ├── theme/
│   └── constants/
├── features/              # Feature-based modules
│   ├── home/             # Dashboard
│   ├── call_shield/      # Real-time call analysis
│   └── doc_scan/         # Document scanning
└── services/             # API clients (pluggable)
```

## Dependencies

- **Riverpod**: State management
- **Dio**: HTTP client
- **animate_do**: Entry animations
- **iconsax**: Premium icons
- **google_fonts**: Typography
