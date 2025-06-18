# frozen_string_literal: true

require_relative '../bindings/alsa'

module Nylera
  # AudioPlayerHelpers holds helper methods for AudioPlayer
  # (skip logic, final teardown, etc.)
  module AudioPlayerHelpers
    private

    def teardown_playback
      ALSA.snd_pcm_drain(@pcm_handle)
      ALSA.snd_pcm_close(@pcm_handle)
      @decoder.close
      @status_cb.call('Stopped')
    end

    def apply_skip
      return if @skip_req[:value].zero?

      secs = @skip_req[:value]
      @decoder.seek_relative(secs)
      @elapsed_mtx.synchronize do
        @elapsed_time[:seconds] += secs
        clamp_elapsed_time
      end
      @skip_req[:value] = 0
    end
  end
end
