# encoding: ASCII-8BIT
##
# basic_types.rb
# Created May, 2017
# By Ron Bowes
#
# See: LICENSE.md
#
# Works on the Memory class to define basic types.
##

require 'h2gb/vault/error'
require 'h2gb/vault/memory/workspace'

module H2gb
  module Vault
    module BasicTypes
      def _make_uint8_t(address:, options:)
        _sanity_check(address: address, length: 1)

        value = @memory.raw[address].ord()

        @memory.define(
          address: address,
          type: :uint8_t,
          value: value,
          length: 1,
        )
      end

      def _make_uint16_t(address:, options:)
        _sanity_check(address: address, length: 2)

        if options[:endian] == :big
          value = @memory.raw[address,2].unpack("n").pop()
        else
          value = @memory.raw[address,2].unpack("v").pop()
        end

        @memory.define(
          address: address,
          type: :uint16_t,
          value: value,
          length: 2,
        )
      end

      def _make_uint32_t(address:, options:)
        _sanity_check(address: address, length: 4)

        if options[:endian] == :big
          value = @memory.raw[address,4].unpack("N").pop()
        else
          value = @memory.raw[address,4].unpack("V").pop()
        end

        @memory.define(
          address: address,
          type: :uint32_t,
          value: value,
          length: 4,
        )
      end

      def _make_offset32(address:, options:)
        _sanity_check(address: address, length: 4)

        if options[:endian] == :big
          value = @memory.raw[address,4].unpack("N").pop()
        else
          value = @memory.raw[address,4].unpack("V").pop()
        end

        @memory.define(
          address: address,
          type: :offset32,
          value: value,
          length: 4,
          refs: { data: [value] },
        )
      end

      def _make_rgb(address:, options:)
        _sanity_check(address: address, length: 3)

        if options[:endian] == :big
          value = @memory.raw[address,3]
        else
          value = @memory.raw[address,3].reverse()
        end

        @memory.define(
          address: address,
          type: :rgb,
          value: value.unpack("H*").pop(),
          length: 3,
        )
      end

      def _make_ntstring(address:, options:)
        str_end = @memory.raw.index("\x00", address)
        if str_end.nil?
          raise(Error, "Couldn't find a NUL byte before the end of memory")
        end

        length = str_end - address + 1

        value = @memory.raw[address, length - 1]
        value = value.bytes.map { |c| (c < 0x20 || c > 0x7F) ? '\x%02x' % c : c.chr }.join()

        @memory.define(
          address: address,
          type: :ntstring,
          value: value,
          length: length,
        )
      end

      def _define_basic_type(item:)
        item[:options] = item[:options] || {}
        case item[:type]
        when :uint8_t
          _make_uint8_t(address: item[:address], options: item[:options])
        when :uint16_t
          _make_uint16_t(address: item[:address], options: item[:options])
        when :uint32_t
          _make_uint32_t(address: item[:address], options: item[:options])
        when :offset32
          _make_offset32(address: item[:address], options: item[:options])
        when :rgb
          _make_rgb(address: item[:address], options: item[:options])
        when :ntstring
          _make_ntstring(address: item[:address], options: item[:options])
        else
          raise Error("Unknown type: %s" % item[:type])
        end
      end
    end
  end
end
