require 'spec_helper'

RSpec.describe Nylera::ALSA do
  describe 'FFI bindings' do
    it 'defines required constants' do
      expect(Nylera::ALSA::SND_PCM_STREAM_PLAYBACK).to eq(0)
      expect(Nylera::ALSA::SND_PCM_FORMAT_S16_LE).to eq(2)
      expect(Nylera::ALSA::SND_PCM_ACCESS_RW_INTERLEAVED).to eq(3)
    end

    it 'responds to required functions' do
      # Skip function tests if library not loaded
      skip "ALSA library not available" unless defined?(Nylera::ALSA.snd_pcm_open)
      
      expect(Nylera::ALSA).to respond_to(:snd_pcm_open)
      expect(Nylera::ALSA).to respond_to(:snd_pcm_set_params)
      expect(Nylera::ALSA).to respond_to(:snd_pcm_writei)
      expect(Nylera::ALSA).to respond_to(:snd_pcm_prepare)
      expect(Nylera::ALSA).to respond_to(:snd_pcm_close)
      expect(Nylera::ALSA).to respond_to(:snd_pcm_drain)
    end
  end
end
