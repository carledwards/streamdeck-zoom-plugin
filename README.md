# Stream Deck Zoom Plugin

Control your Zoom meetings directly from your Stream Deck. Features include:
- Mute/unmute audio
- Start/stop video
- Share screen
- Record to cloud/local
- Leave meeting
- And more!

More info: https://lostdomain.org/stream-deck-plugin-for-zoom/

## Building from Source (macOS)

These instructions are specifically for building on macOS Sonoma 15.1 (Sequoia). Windows build instructions will be added in a future update.

### Prerequisites

1. Install Xcode Command Line Tools:
```bash
xcode-select --install
```

2. Install Homebrew (if not already installed):
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

3. Install CMake using Homebrew:
```bash
brew install cmake
```

Note: The macOS system Clang compiler (installed with Xcode Command Line Tools) will be used for building.

### Build Instructions (macOS)

1. Clone the repository:
```bash
git clone https://github.com/lostdomain/streamdeck-zoom-plugin.git
cd streamdeck-zoom-plugin
```

2. Build the plugin:
```bash
make clean    # Clean any previous build artifacts
make package  # Build and package the plugin
```

This will:
- Build the plugin binary
- Copy all required assets
- Package everything into a .streamDeckPlugin file in the `build` directory

## Installation

### Easy Install
1. Double-click the `com.lostdomain.zoom.streamDeckPlugin` file in the `build` directory
2. Stream Deck software will automatically install the plugin

### Manual Install
The plugin will be installed to:
- `~/Library/Application Support/com.elgato.StreamDeck/Plugins/`

## Development

The plugin is built using the Stream Deck SDK. The main components are:
- `Sources/`: Core plugin implementation
- `StreamDeckSDK/`: Stream Deck SDK integration
- `sdPlugin/`: Plugin assets and manifest
