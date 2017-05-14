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
require 'h2gb/vault/memory/memory'

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

      def _define_basic_type(item:)
        case item[:type]
        when :uint8_t
          _make_uint8_t(address: item[:address], options: item[:options] || {})
        when :uint16_t
          _make_uint16_t(address: item[:address], options: item[:options] || {})
        when :uint32_t
          _make_uint32_t(address: item[:address], options: item[:options] || {})
        when :offset32
          _make_offset32(address: item[:address], options: item[:options] || {})
        when :rgb
          _make_rgb(address: item[:address], options: item[:options] || {})
        else
          # TODO: This exception isn't working, but I plan to replace it anyways
          puts item
          raise Error("Unknown type: %s" % item[:type])
        end
      end
    end
  end
end
