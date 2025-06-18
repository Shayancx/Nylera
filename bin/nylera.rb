#!/usr/bin/env ruby
# frozen_string_literal: true

# Adjust LOAD_PATH so Ruby can find our lib/ folder
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'constants'
require 'core/mp3_player_app'

module Nylera
  # Simple CLI entry point for Nylera
end

if __FILE__ == $PROGRAM_NAME
  # Detect user-specified music directory or default
  music_dir = ENV.fetch('MUSIC_DIR', Nylera::Constants::DEFAULT_MUSIC_DIR)

  unless Dir.exist?(music_dir)
    warn "Music directory not found: #{music_dir}"
    exit 1
  end

  app = Nylera::MP3PlayerApp.new(music_dir)
  app.run
end
