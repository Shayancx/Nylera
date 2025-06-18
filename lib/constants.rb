# frozen_string_literal: true

module Nylera
  module Constants
    DEFAULT_MUSIC_DIR = File.expand_path('~/Musik')
    BUFFER_SIZE       = 1024

    BOX_CORNER_TOP_LEFT     = '┌'
    BOX_CORNER_TOP_RIGHT    = '┐'
    BOX_CORNER_BOTTOM_LEFT  = '└'
    BOX_CORNER_BOTTOM_RIGHT = '┘'
    BOX_HORIZONTAL          = '─'
    BOX_VERTICAL            = '│'

    NAV_BOX_WIDTH     = 37
    INFO_BOX_HEIGHT   = 5
    DOUBLE_TAP_WINDOW = 0.3
  end
end
