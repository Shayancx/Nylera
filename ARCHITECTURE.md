# Nylera Architecture

## Overview

Nylera is a high-performance terminal MP3 player built with Ruby. It uses a modular architecture with clear separation between audio processing, user interface, and control logic.

## Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        Nylera Application                      │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────┐    ┌──────────────┐    ┌────────────────┐ │
│  │   MainTui   │    │ MP3PlayerApp │    │ Configuration  │ │
│  │  (UI Layer) │◄───┤  (Controller) ├───►│   (Settings)   │ │
│  └──────┬──────┘    └───────┬──────┘    └────────────────┘ │
│         │                    │                                │
│         │                    ▼                                │
│         │           ┌────────────────┐                       │
│         │           │  AudioPlayer   │                       │
│         │           │ (ALSA Output)  │                       │
│         │           └───────┬────────┘                       │
│         │                   │                                │
│         │                   ▼                                │
│         │           ┌────────────────┐                       │
│         │           │  MP3Decoder    │                       │
│         │           │ (mpg123 wrap)  │                       │
│         │           └────────────────┘                       │
│         │                                                    │
│         └──────────────────┬─────────────────────────────────┤
│                            │                                 │
│  ┌──────────────────────────▼──────────────────────────────┐ │
│  │                     TUI Modules                          │ │
│  ├────────────┬────────────┬────────────┬─────────────────┤ │
│  │ BoxDrawer  │ Navigation │  InfoBox   │ InputHandler    │ │
│  │            │    Box     │            │                 │ │
│  ├────────────┼────────────┼────────────┼─────────────────┤ │
│  │ProgressBar│ SearchHand │ ColorMgr   │ DirtyTracker    │ │
│  │            │    ler     │            │ (Optimization)  │ │
│  └────────────┴────────────┴────────────┴─────────────────┘ │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. MP3PlayerApp (Controller)
- **Responsibility**: Main application controller
- **Key Functions**:
  - Manages playlist and current track
  - Controls playback state (play/pause/stop)
  - Handles user actions from UI
  - Manages threading for audio playback

### 2. AudioPlayer (Audio Output)
- **Responsibility**: ALSA audio device management
- **Key Functions**:
  - Opens and configures PCM devices
  - Writes decoded frames to sound card
  - Manages playback timing
  - Handles skip/seek operations

### 3. MP3Decoder (Decoding)
- **Responsibility**: MP3 file decoding via mpg123
- **Key Functions**:
  - Decodes MP3 frames to PCM data
  - Extracts format information
  - Provides duration and seek capabilities
  - Extracts ID3 metadata

### 4. MainTui (User Interface)
- **Responsibility**: Terminal UI management
- **Key Functions**:
  - Renders navigation and info boxes
  - Handles user input
  - Updates display based on state
  - Manages search functionality

## Performance Optimizations

### 1. Dirty Tracking (DirtyTracker)
Prevents screen flickering by only redrawing changed regions:
- Tracks which UI regions have changed
- Compares content before drawing
- Batches screen updates
- Only calls refresh when necessary

### 2. Partial Screen Updates
- No full screen clears except on resize
- Individual component updates
- Content caching to avoid redundant draws
- Optimized string operations

### 3. Efficient Threading
- Separate threads for UI and audio
- Minimal mutex usage
- Lock-free skip requests
- Async status updates

## Data Flow

### Playback Flow
1. User selects track in UI
2. MP3PlayerApp receives action
3. Creates MP3Decoder for file
4. Creates AudioPlayer with decoder
5. Starts playback thread
6. AudioPlayer loop:
   - Decoder provides PCM frames
   - Frames written to ALSA
   - Elapsed time updated
   - Status callbacks to UI

### UI Update Flow
1. Main loop checks for changes (20ms intervals)
2. DirtyTracker identifies changed regions
3. Only dirty regions are redrawn
4. Single refresh call if any updates

## Thread Safety

### Shared State
- `@elapsed_time`: Protected by mutex
- `@pause_flag`: Atomic hash access
- `@stop_flag`: Atomic hash access
- `@status`: Protected by mutex

### Thread Communication
- UI thread: Handles input, renders display
- Audio thread: Decodes and plays audio
- Communication via shared flags and callbacks

## Configuration

Environment variables control behavior:
- `NYLERA_MUSIC_DIR`: Music directory path
- `NYLERA_BUFFER_SIZE`: Audio buffer size
- `NYLERA_REFRESH_RATE`: UI refresh rate (Hz)
- `NYLERA_DEBUG`: Enable debug output

## Error Handling

### Audio Errors
- Device not found: Clear user message
- Permission denied: Suggests fix
- Device busy: Suggests closing other apps

### File Errors
- Invalid MP3: Skips to next track
- Missing file: Removes from playlist
- Metadata errors: Uses defaults

## Future Enhancements

1. **Format Support**: Add FLAC, OGG, AAC
2. **Network Streaming**: HTTP/HTTPS sources
3. **Visualizations**: Spectrum analyzer
4. **Playlists**: M3U/PLS support
5. **Equalizer**: Frequency adjustment
