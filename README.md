# CineDream

CineDream is a powerful iOS streaming application built with Swift and UIKit. It uses TMDB for movie and TV show data and various scrapers to find streaming sources.

## Features

- **Modern UI**: Sleek, Netflix-inspired interface with dark mode and glassmorphism.
- **Multiple Sources**: Automatically scrapes multiple servers to find the best streaming link.
- **Native Player**: Custom AVPlayer with gestures for brightness, volume, and seeking.
- **Embedded Web Player**: Support for web-based embed players when native sources aren't available.
- **Watch History & Watch Later**: Keep track of what you've watched and what you want to see.
- **Browse & Filter**: Discover content by genre, language, and year.
- **PiP Support**: Picture-in-Picture support for native video sources.

## Getting Started

### Prerequisites

- macOS with Xcode 16.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/CineDream.git
   cd CineDream
   ```

2. Generate the Xcode project:
   ```bash
   xcodegen generate
   ```

3. Open `CineDream.xcodeproj` and run on your device or simulator.

## Configuration

The app requires a [TMDB API key](https://www.themoviedb.org/settings/api). The key is **not stored in the repository** to prevent abuse.

### For Development (Local)

**Option A — Environment variable (recommended):**
```bash
# macOS / Linux
export TMDB_API_KEY=your_actual_key_here
xcodegen generate
open CineDream.xcodeproj
```

**Option B — Xcode build setting:**
1. Open `CineDream.xcodeproj` in Xcode
2. Select the `CineDream` target → Build Settings
3. Under User-Defined, add `TMDB_API_KEY` with your key

**Option C — xcconfig file (advanced):**
```bash
# Copy the template
cp CineDream/Config.xcconfig.example CineDream/Config.xcconfig
# Edit Config.xcconfig and add your key
```

### For CI / GitHub Actions

When enabling the GitHub Actions workflow, add a repository secret:
1. Go to **Settings → Secrets and variables → Actions**
2. Add a new repository secret named `TMDB_API_KEY` with your key as the value
3. The workflow automatically injects it into the build

## Security

- **The API key is never committed to the repository.** It is injected at build time via environment variables or build settings.
- `.xcconfig` files are gitignored to prevent accidental commits.
- The GitHub Actions workflow uses encrypted secrets to protect the key during CI.
- If you fork this repository, **you must provide your own TMDB API key** — the original key is not included.

---

**Note:** This app is for educational purposes. Respect copyright laws in your jurisdiction.
## CI/CD

The project includes a GitHub Action to build an unsigned IPA on every push to the `main` branch.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Credits

- Data provided by [TMDB](https://www.themoviedb.org/).
- Developed by Zee.

## Disclaimer

This application is for educational purposes only. The developers do not host any content and are not responsible for the content provided by third-party scrapers. Users are responsible for complying with their local laws regarding streaming.
