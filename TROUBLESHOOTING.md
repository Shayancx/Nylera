# Nylera Troubleshooting Guide

## Common Issues

### 1. No Sound Output

**Symptoms**: Player shows "Playing" but no audio

**Solutions**:
```bash
# Check if ALSA is working
speaker-test -c 2

# List available devices
aplay -l

# Check if PulseAudio is running
pactl info

# Try different audio device
ALSA_CARD=1 ruby bin/nylera.rb
```

### 2. "Permission denied" Error

**Symptoms**: Error opening audio device

**Solutions**:
```bash
# Add user to audio group
sudo usermod -a -G audio $USER
# Log out and back in

# Check permissions
ls -la /dev/snd/
```

### 3. Screen Corruption

**Symptoms**: Garbled display, incorrect characters

**Solutions**:
```bash
# Check terminal encoding
echo $LANG
export LANG=en_US.UTF-8

# Reset terminal
reset

# Try different terminal
TERM=xterm ruby bin/nylera.rb
```

### 4. High CPU Usage

**Symptoms**: Nylera uses excessive CPU

**Debug Steps**:
1. Enable debug mode:
   ```bash
   export NYLERA_DEBUG=true
   ```

2. Check refresh rate:
   ```bash
   export NYLERA_REFRESH_RATE=20
   ```

3. Profile the app:
   ```bash
   ruby -rprofile bin/nylera.rb 2>profile.log
   ```

### 5. Metadata Not Showing

**Symptoms**: Song info shows "Unknown"

**Solutions**:
```bash
# Check file with id3v2
id3v2 -l yourfile.mp3

# Re-tag files
id3v2 -a "Artist" -t "Title" yourfile.mp3
```

## Error Messages

### "No MP3 files found"
- Check NYLERA_MUSIC_DIR or MUSIC_DIR environment variable
- Verify directory contains .mp3 files
- Check file permissions

### "Failed to create mpg123 handle"
- Install libmpg123: `sudo apt-get install libmpg123-dev`
- Check library path: `ldconfig -p | grep mpg123`

### "Audio device is busy"
- Close other audio applications
- Check with: `lsof /dev/snd/*`
- Kill PulseAudio: `pulseaudio -k`

## Debug Mode

Enable comprehensive debugging:
```bash
export NYLERA_DEBUG=true
export RUBY_DEBUG=true
```

Debug output includes:
- Audio device selection
- Buffer underruns
- Frame timings
- UI refresh cycles

## Logging

Create detailed logs:
```bash
# Redirect stderr to file
ruby bin/nylera.rb 2>nylera.log

# With timestamps
ruby bin/nylera.rb 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' > nylera.log
```

## Getting Help

When reporting issues, include:
1. Ruby version: `ruby --version`
2. OS and version: `uname -a`
3. Audio system: `pactl info` or `aplay --version`
4. Error messages from debug mode
5. Sample MP3 that causes the issue

## Known Limitations

1. **Remote Sessions**: Limited Unicode support over SSH
2. **WSL**: Audio may require PulseAudio server on Windows
3. **macOS**: Currently Linux-only (ALSA dependency)
4. **File Formats**: Only MP3 supported (no FLAC/OGG yet)
