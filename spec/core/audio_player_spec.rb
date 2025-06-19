require 'spec_helper'

RSpec.describe Nylera::AudioPlayer do
  # Skip all tests if ALSA module not loaded
  before(:all) do
    skip "ALSA library not available" unless defined?(Nylera::ALSA)
  end
  
  let(:decoder) { double('decoder', channels: 2, rate: 44100, duration_seconds: 180.0) }
  let(:elapsed_time) { { seconds: 0.0 } }
  let(:elapsed_mutex) { Mutex.new }
  let(:status_cb) { ->(status) { @last_status = status } }
  
  before do
    @last_status = nil
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
    let(:player) { described_class.new(decoder, elapsed_time, elapsed_mutex, status_cb) }
    
    it 'sets skip request value' do
      player.request_skip(10)
      expect(player.instance_variable_get(:@skip_req)[:value]).to eq(10)
    end
  end
end
