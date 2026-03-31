# FlixLocal 🎬

A Netflix-style local video player application for Android & iOS built with Flutter.

---

## ✨ Features

| Feature | Description |
|---|---|
| 🎬 **Netflix UI** | Dark cinematic interface with red accent colors |
| 📂 **Local Playback** | Pick individual videos or scan entire folders |
| ▶️ **Full Controls** | Play, pause, seek, volume, fullscreen via Chewie |
| 📱 **Auto-Rotate** | Landscape mode for fullscreen playback |
| 🔖 **Watch Progress** | Per-video progress tracking & resume |
| ❤️ **Favorites** | Mark and browse your favorite videos |
| 🔍 **Search** | Instant search across your library |
| 📊 **Library Grid** | Netflix-style 2-column grid view |
| 🎭 **Featured Banner** | Random featured video on the home screen |
| 💾 **Persistent State** | Progress and favorites survive app restarts |

---

## 📦 Supported Formats

`MP4` `MKV` `AVI` `MOV` `WMV` `FLV` `WebM` `M4V` `3GP` `TS`

---

## 🚀 Setup & Run

### Prerequisites
- Flutter SDK `>=3.0.0`
- Android Studio / VS Code with Flutter extension
- Android device or emulator (API 21+)

### Steps

```bash
# 1. Clone / unzip the project
cd flix_local

# 2. Install dependencies
flutter pub get

# 3. Run on device
flutter run
```

### Build Release APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Build App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point & theme
├── models/
│   └── video_model.dart         # Video data model
├── providers/
│   └── video_provider.dart      # State management (ChangeNotifier)
├── screens/
│   ├── splash_screen.dart       # Animated splash screen
│   ├── main_shell.dart          # Bottom navigation scaffold
│   ├── home_screen.dart         # Netflix-style home
│   ├── browse_screen.dart       # Full library grid
│   ├── search_screen.dart       # Search & recently played
│   ├── favorites_screen.dart    # Favorites collection
│   └── video_player_screen.dart # Chewie video player
└── widgets/
    ├── video_card.dart          # Video card & continue-watching card
    ├── featured_banner.dart     # Hero banner widget
    └── section_header.dart      # Reusable section title
```

---

## 📱 Screenshots Overview

### Home Screen
- Animated splash with FlixLocal branding
- Featured random video hero banner
- "Continue Watching" horizontal strip (shows in-progress videos)
- "Recently Added" horizontal strip
- "All Videos" 2-column grid
- FAB / icon to add videos/folders

### Library (Browse)
- Full grid of all videos
- Category filter chips
- Stats bar (total count, favorites)
- Sort options

### Search
- Live search filter
- Recently played list
- Full video list

### Favorites
- Dedicated grid for favorited videos

### Player
- Full video controls via Chewie
- Landscape fullscreen support
- Resume from last position
- Progress bar
- Favorite toggle
- File metadata display

---

## 🔧 Dependencies

```yaml
video_player: ^2.8.2       # Flutter video playback
chewie: ^1.7.4             # Advanced video player controls
file_picker: ^8.0.0+1      # Pick files and folders
provider: ^6.1.2           # State management
shared_preferences: ^2.2.2 # Persistent storage
flutter_animate: ^4.5.0    # Animations
google_fonts: ^6.2.1       # Outfit + Bebas Neue fonts
path: ^1.9.0               # File path utilities
```

---

## 🎨 Design System

- **Background**: `#0A0A0F` (deep space black)
- **Surface**: `#141420` (dark navy)
- **Primary (accent)**: `#E50914` (Netflix red)
- **Secondary**: `#FF6B35` (warm orange)
- **Typography**: Outfit (body), Bebas Neue (display)

---

## ⚙️ Android Permissions

The app requests these permissions at runtime:

- `READ_EXTERNAL_STORAGE` (Android ≤12)
- `READ_MEDIA_VIDEO` (Android 13+)
- `READ_MEDIA_AUDIO` (Android 13+)

> On first launch the app will request storage permission. Grant it to enable video browsing.

---

## 🛠 Troubleshooting

| Issue | Solution |
|---|---|
| Videos won't load | Grant storage permission in phone Settings |
| Black screen on player | Ensure `android:hardwareAccelerated="true"` in manifest |
| Folder scan slow | Large folders with many files take a moment |
| MKV not playing | Depends on device codec support; MP4/WebM work best |

---

## 📄 License

MIT License — free to use and modify.
