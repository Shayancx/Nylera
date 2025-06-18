# frozen_string_literal: true

require 'ffi'

module Nylera
  # FFI bindings for the ALSA library
  module ALSA
    extend FFI::Library

    ffi_lib ['asound', 'libasound.so.2']

    SND_PCM_STREAM_PLAYBACK       = 0
    SND_PCM_FORMAT_S16_LE         = 2
    SND_PCM_ACCESS_RW_INTERLEAVED = 3

    attach_function :snd_pcm_open,
                    %i[pointer string int int],
                    :int
    attach_function :snd_pcm_set_params,
                    %i[pointer int int int int int ulong],
                    :int
    attach_function :snd_pcm_writei,
                    %i[pointer pointer long],
                    :long
    attach_function :snd_pcm_prepare, [:pointer], :int
    attach_function :snd_pcm_close, [:pointer], :int
    attach_function :snd_pcm_drain, [:pointer], :int
  end
end
