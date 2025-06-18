# frozen_string_literal: true

module Nylera
  # Base error class for Nylera-specific exceptions
  class NyleraError < StandardError; end

  # Raised when audio playback fails
  class PlaybackError < NyleraError; end

  # Raised when a file cannot be decoded
  class DecodingError < NyleraError; end

  # Raised when audio device cannot be opened
  class AudioDeviceError < NyleraError; end

  # Raised when metadata extraction fails
  class MetadataError < NyleraError; end

  # Raised when UI operations fail
  class UIError < NyleraError; end
end
