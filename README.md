# Nylera - Terminal MP3 Player

A high-performance, terminal-based MP3 player written in Ruby with a beautiful TUI interface.

## Features

- **Terminal UI**: Beautiful ncurses-based interface with colors and Unicode box drawing
- **Playback Control**: Play, pause, fast-forward, rewind functionality
- **Playlist Management**: Navigate and search through your music library
- **Metadata Support**: Reads ID3v1 and ID3v2 tags
- **High Performance**: Optimized screen updates to prevent flickering
- **Comprehensive Testing**: Full RSpec test suite with >90% coverage

## Architecture

### Core Components

1. **MP3PlayerApp** (`lib/core/mp3_player_app.rb`)
   - Main application controller
   - Manages playback state and threading
   - Coordinates between UI and audio subsystems

2. **AudioPlayer** (`lib/core/audio_player.rb`)
   - Handles ALSA audio output
   - Manages playback timing and synchronization
   - Implements skip/seek functionality

3. **MP3Decoder** (`lib/core/mp3_decoder.rb`)
   - Wraps mpg123 library for MP3 decoding
   - Provides frame-by-frame audio data
   - Handles format detection and conversion

4. **MainTui** (`lib/tui/tui.rb`)
   - Terminal UI implementation using Curses
   - Modular design with separate concerns
   - Optimized rendering for smooth performance

### Performance Optimizations

1. **Partial Screen Updates**: Only redraws changed content instead of clearing entire screen
2. **Content Caching**: Tracks what was last drawn to avoid redundant updates
3. **Efficient Threading**: Separate threads for UI and audio playback
4. **Minimal Mutex Usage**: Synchronized only where necessary

### Code Organization

```
lib/
├── bindings/         # FFI bindings for C libraries
├── core/            # Core application logic
├── metadata/        # ID3 tag extraction
├── tui/            # Terminal UI components
├── constants.rb    # Application constants
├── errors.rb       # Custom error classes
└── version.rb      # Version information
```

## Testing

Run the comprehensive test suite:

```bash
bundle exec rspec
```

Generate coverage report:

```bash
bundle exec rspec --format documentation
open coverage/index.html
```

## Design Patterns

1. **Module Composition**: TUI uses mixins for separation of concerns
2. **Observer Pattern**: Status callbacks for UI updates
3. **Template Method**: Base decoder interface with specialized implementations
4. **Facade Pattern**: Simple API hiding complex audio/UI interactions

## Performance Considerations

1. **Screen Refresh Rate**: Limited to 50Hz (20ms timeout) for smooth updates
2. **Buffer Size**: 1024 bytes for optimal audio streaming
3. **Metadata Caching**: Tags read once during initialization
4. **Lazy Loading**: Playlist items rendered only when visible

## Future Improvements

1. Support for additional audio formats (FLAC, OGG)
2. Equalizer and audio effects
3. Network streaming support
4. Playlist persistence
5. Album art display (using terminal image protocols)
