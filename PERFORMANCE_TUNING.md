# Nylera Performance Tuning Guide

## Overview

This guide helps you optimize Nylera for your system and use case.

## Quick Fixes

### 1. Screen Flickering
If you experience screen flickering:

```bash
# Reduce refresh rate (default: 50Hz)
export NYLERA_REFRESH_RATE=30

# Enable debug mode to see what's being redrawn
export NYLERA_DEBUG=true
```

### 2. Audio Crackling/Skipping

For PulseAudio systems:
```bash
# Increase buffer size
export NYLERA_BUFFER_SIZE=2048

# Check PulseAudio latency
pactl list sinks | grep Latency
```

For direct ALSA:
```bash
# Use hardware device directly
export ALSA_CARD=0
export ALSA_PCM_DEVICE=0
```

### 3. High CPU Usage

```bash
# Profile the application
ruby -rprofile bin/nylera.rb

# Or use stackprof
gem install stackprof
ruby -rstackprof bin/nylera.rb
```

## Advanced Tuning

### 1. Terminal Settings

For best performance:
- Use a GPU-accelerated terminal (Alacritty, Kitty)
- Disable terminal transparency
- Use bitmap fonts
- Reduce terminal scrollback

### 2. System Optimization

```bash
# Increase audio thread priority
sudo nice -n -10 ruby bin/nylera.rb

# Or use real-time scheduling
sudo chrt -f 50 ruby bin/nylera.rb
```

### 3. Build Optimizations

```bash
# Compile Ruby with optimizations
CFLAGS="-O3 -march=native" rbenv install 3.2.0

# Use jemalloc for better memory performance
LD_PRELOAD=/usr/lib/libjemalloc.so ruby bin/nylera.rb
```

## Benchmarking

### UI Performance
```bash
# Run performance specs
bundle exec rspec --tag performance

# Benchmark specific operations
ruby -rbenchmark -e 'require "./lib/tui/tui"; Benchmark.bm { |x| x.report { 1000.times { ... } } }'
```

### Audio Performance
```bash
# Monitor ALSA underruns
cat /proc/asound/card0/pcm0p/sub0/status

# Check system audio latency
jack_iodelay (if using JACK)
```

## Troubleshooting

### High Memory Usage
1. Check for memory leaks:
   ```ruby
   require 'objspace'
   ObjectSpace.trace_object_allocations_start
   # ... run app ...
   ObjectSpace.dump_all(output: File.open('heap.json', 'w'))
   ```

2. Analyze with heapy:
   ```bash
   gem install heapy
   heapy heap.json
   ```

### Profiling Tools

1. **CPU Profiling**:
   ```ruby
   require 'ruby-prof'
   RubyProf.start
   # ... code to profile ...
   result = RubyProf.stop
   printer = RubyProf::FlatPrinter.new(result)
   printer.print(STDOUT)
   ```

2. **Memory Profiling**:
   ```ruby
   require 'memory_profiler'
   report = MemoryProfiler.report do
     # ... code to profile ...
   end
   report.pretty_print
   ```

## Configuration Examples

### Low-End System
```bash
export NYLERA_REFRESH_RATE=20
export NYLERA_BUFFER_SIZE=512
export NYLERA_NAV_WIDTH=30
```

### High-End System
```bash
export NYLERA_REFRESH_RATE=60
export NYLERA_BUFFER_SIZE=4096
export NYLERA_NAV_WIDTH=50
```

### Remote/SSH Session
```bash
export NYLERA_REFRESH_RATE=10
export TERM=xterm-256color
```
