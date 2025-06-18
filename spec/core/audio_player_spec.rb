require 'spec_helper'

RSpec.describe Nylera::AudioPlayer do
  # Skip all tests if ALSA module not loaded
  before(:all) do
    skip "ALSA library not available" unless defined?(Nylera::ALSA)
  end
  
  let(:decoder) { double('decoder', channels: 2, rate: 44100, duration_seconds: 180.0) }
  let(:elapsed_time) { { seconds: 0.0 } }
  let(:elapsed_mutex) { Mutex.new }
  let(:status_cb) { double('status_cb') }
  let(:player) { described_class.new(decoder, elapsed_time, elapsed_mutex, status_cb) }

  before do
    # Mock ALSA functions
    allow(Nylera::ALSA).to receive(:snd_pcm_open).and_return(0)
    allow(Nylera::ALSA).to receive(:snd_pcm_set_params).and_return(0)
    allow_any_instance_of(FFI::MemoryPointer).to receive(:read_pointer).and_return(double('pcm_handle'))
  end

  describe '#initialize' do
    it 'opens PCM device and sets hardware parameters' do
      expect(Nylera::ALSA).to receive(:snd_pcm_open)
      expect(Nylera::ALSA).to receive(:snd_pcm_set_params)
      described_class.new(decoder, elapsed_time, elapsed_mutex, status_cb)
    end
  end

  describe '#request_skip' do
    it 'sets skip request value' do
      player.request_skip(10)
      expect(player.instance_variable_get(:@skip_req)[:value]).to eq(10)
    end
  end

  describe '#play', :requires_audio_hardware do
    let(:pause_flag) { { value: false } }
    let(:stop_flag) { { value: false } }

    before do
      allow(decoder).to receive(:decode).and_return('audio_data', '')
      allow(decoder).to receive(:close)
      allow(decoder).to receive(:seek_relative)
      allow(status_cb).to receive(:call)
      allow(Nylera::ALSA).to receive(:snd_pcm_writei).and_return(100)
      allow(Nylera::ALSA).to receive(:snd_pcm_drain)
      allow(Nylera::ALSA).to receive(:snd_pcm_close)
      allow(Thread).to receive(:pass)
    end

    it 'plays audio until stopped' do
      stop_flag[:value] = true
      expect(status_cb).to receive(:call).with('Playing')
      expect(status_cb).to receive(:call).with('Stopped')
      player.play(pause_flag, stop_flag)
    end

    it 'handles pause state' do
      pause_flag[:value] = true
      stop_flag[:value] = true
      expect(status_cb).to receive(:call).with('Playing')
      expect(status_cb).to receive(:call).with('Paused')
      expect(status_cb).to receive(:call).with('Stopped')
      player.play(pause_flag, stop_flag)
    end
  end
end
