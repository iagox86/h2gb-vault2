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
require 'h2gb/vault/workspace'

module H2gb
  module Vault
    module BasicTypes
      def _make_uint8_t(block_name:, address:, options:)
        _sanity_check(block_name: block_name, address: address, length: 1)

        value = @workspace.raw(block_name: block_name)[address].ord()

        @workspace.define(
          block_name: block_name,
          address: address,
          type: :uint8_t,
          value: value,
          length: 1,
        )
      end

      def _make_uint16_t(block_name:, address:, options:)
        _sanity_check(block_name: block_name, address: address, length: 2)

        if options[:endian] == :big
          value = @workspace.raw(block_name: block_name)[address,2].unpack("n").pop()
        else
          value = @workspace.raw(block_name: block_name)[address,2].unpack("v").pop()
        end

        @workspace.define(
          block_name: block_name,
          address: address,
          type: :uint16_t,
          value: value,
          length: 2,
        )
      end

      def _make_uint32_t(block_name:, address:, options:)
        _sanity_check(block_name: block_name, address: address, length: 4)

        if options[:endian] == :big
          value = @workspace.raw(block_name: block_name)[address,4].unpack("N").pop()
        else
          value = @workspace.raw(block_name: block_name)[address,4].unpack("V").pop()
        end

        @workspace.define(
          block_name: block_name,
          address: address,
          type: :uint32_t,
          value: value,
          length: 4,
        )
      end

      def _make_offset32(block_name:, address:, options:)
        _sanity_check(block_name: block_name, address: address, length: 4)

        if options[:endian] == :big
          value = @workspace.raw(block_name: block_name)[address,4].unpack("N").pop()
        else
          value = @workspace.raw(block_name: block_name)[address,4].unpack("V").pop()
        end

        @workspace.define(
          block_name: block_name,
          address: address,
          type: :offset32,
          value: value,
          length: 4,
          refs: { data: [value] },
        )
      end

      def _make_rgb(block_name:, address:, options:)
        _sanity_check(block_name: block_name, address: address, length: 3)

        if options[:endian] == :big
          value = @workspace.raw(block_name: block_name)[address,3]
        else
          value = @workspace.raw(block_name: block_name)[address,3].reverse()
        end

        @workspace.define(
          block_name: block_name,
          address: address,
          type: :rgb,
          value: value.unpack("H*").pop(),
          length: 3,
        )
      end

      def _make_ntstring(block_name:, address:, options:)
        str_end = @workspace.raw(block_name: block_name).index("\x00", address)
        if str_end.nil?
          raise(Error, "Couldn't find a NUL byte before the end of memory")
        end

        length = str_end - address + 1

        value = @workspace.raw(block_name: block_name)[address, length - 1]
        value = value.bytes.map { |c| (c < 0x20 || c > 0x7F) ? '\x%02x' % c : c.chr }.join()

        @workspace.define(
          block_name: block_name,
          address: address,
          type: :ntstring,
          value: value,
          length: length,
        )
      end

      def _define_basic_type(block_name:, item:)
        item[:options] = item[:options] || {}
        case item[:type]
        when :uint8_t
          _make_uint8_t(block_name: block_name, address: item[:address], options: item[:options])
        when :uint16_t
          _make_uint16_t(block_name: block_name, address: item[:address], options: item[:options])
        when :uint32_t
          _make_uint32_t(block_name: block_name, address: item[:address], options: item[:options])
        when :offset32
          _make_offset32(block_name: block_name, address: item[:address], options: item[:options])
        when :rgb
          _make_rgb(block_name: block_name, address: item[:address], options: item[:options])
        when :ntstring
          _make_ntstring(block_name: block_name, address: item[:address], options: item[:options])
        else
          raise Error("Unknown type: %s" % item[:type])
        end
      end
    end
  end
end
