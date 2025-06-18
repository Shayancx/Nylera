# frozen_string_literal: true

require 'ffi'

module Nylera
  # FFI bindings for the mpg123 library
  module MPG123
    extend FFI::Library

    ffi_lib ['mpg123', 'libmpg123.so.0', 'libmpg123.dylib']

    MPG123_OK            = 0
    MPG123_DONE          = -12
    MPG123_NEW_FORMAT    = -10
    MPG123_ENC_SIGNED_16 = 3
    SEEK_SET             = 0

    typedef :pointer, :mpg123_handle

    attach_function :mpg123_init, [], :int
    attach_function :mpg123_new, %i[string pointer], :mpg123_handle
    attach_function :mpg123_open, %i[mpg123_handle string], :int
    attach_function :mpg123_getformat,
                    %i[mpg123_handle pointer pointer pointer],
                    :int
    attach_function :mpg123_read,
                    %i[mpg123_handle pointer size_t pointer],
                    :int
    attach_function :mpg123_close, [:mpg123_handle], :int
    attach_function :mpg123_delete, [:mpg123_handle], :void
    attach_function :mpg123_exit, [], :void
    attach_function :mpg123_strerror, [:mpg123_handle], :string
    attach_function :mpg123_format_none, [:mpg123_handle], :int
    attach_function :mpg123_format,
                    %i[mpg123_handle long int int],
                    :int
    attach_function :mpg123_length, [:mpg123_handle], :long
    attach_function :mpg123_tell, [:mpg123_handle], :long
    attach_function :mpg123_seek,
                    %i[mpg123_handle long int],
                    :long
  end
end
