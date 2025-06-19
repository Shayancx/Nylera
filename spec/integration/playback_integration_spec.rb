require 'spec_helper'
require 'tempfile'

RSpec.describe 'Playback Integration', :integration do
  let(:music_dir) { Dir.mktmpdir }
  let(:test_mp3) { File.join(music_dir, 'test.mp3') }
  
  before do
    # Create a minimal MP3 file for testing
    File.write(test_mp3, "\xFF\xFB\x90\x00" * 100)
    
    # Mock audio libraries
    allow(Nylera::MPG123).to receive(:mpg123_init)
    allow(Nylera::MPG123).to receive(:mpg123_exit)
    allow(Nylera::ALSA).to receive(:snd_pcm_open).and_return(0)
    allow(Nylera::ALSA).to receive(:snd_pcm_set_params).and_return(0)
  end
  
  after do
    FileUtils.rm_rf(music_dir)
  end

  it 'initializes player with playlist' do
    app = Nylera::MP3PlayerApp.new(music_dir)
    expect(app.instance_variable_get(:@playlist)).not_to be_empty
  end

  it 'handles play/pause cycle' do
    app = Nylera::MP3PlayerApp.new(music_dir)
    
    # Mock the TUI
    tui = double('tui', 
      update: nil, 
      filtered_playlist: [test_mp3],
      :instance_variable_set => nil
    )
    app.instance_variable_set(:@tui, tui)
    
    # Mock decoder and audio player
    decoder = double('decoder',
      channels: 2,
      rate: 44100,
      duration_seconds: 180.0,
      title: 'Test Song',
      artist: 'Test Artist',
      album: 'Test Album',
      genre: 'Test Genre'
    )
    
    allow(Nylera::MP3Decoder).to receive(:new).and_return(decoder)
    
    audio_player = double('audio_player')
    allow(audio_player).to receive(:play)
    allow(Nylera::AudioPlayer).to receive(:new).and_return(audio_player)
    
    # Mock the player thread
    allow(Thread).to receive(:new).and_yield
    
    # Start playback
    app.send(:play_track, 0)
    
    # Verify status was set
    status = app.send(:current_status)
    expect(['Playing', 'Ready']).to include(status)
    
    # Toggle pause
    app.send(:toggle_pause)
    expect(app.instance_variable_get(:@pause_flag)[:value]).to be true
  end
end
