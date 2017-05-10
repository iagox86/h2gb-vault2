##
# basic_types.rb
# Created May, 2017
# By Ron Bowes
#
# See: LICENSE.md
#
# Works on the Memory class to define basic types.
##

require 'h2gb/vault/memory/memory'
require 'h2gb/vault/memory/memory_error'

module H2gb
  module Vault
    module BasicTypes
      def _make_uint8_t(address:, options:, user_defined:)
        _sanity_check(address: address, length: 1)

        value = @memory.raw[address].ord()

        @memory.define(
          address: address,
          type: :uint8_t,
          value: value,
          length: 1,
          user_defined: user_defined,
        )
      end

      def _make_uint16_t(address:, options:, user_defined:)
        _sanity_check(address: address, length: 2)

        if options[:endian] == :big_endian
          value = @memory.raw[address,2].unpack("n").pop()
        else
          value = @memory.raw[address,2].unpack("v").pop()
        end

        @memory.define(
          address: address,
          type: :uint16_t,
          value: value,
          length: 2,
          user_defined: user_defined,
        )
      end

      def _define_basic_type(item:)
        case item[:type]
        when :uint8_t
          _make_uint8_t(address: item[:address], options: item[:options] || {}, user_defined: item[:user_defined])
        when :uint16_t
          _make_uint16_t(address: item[:address], options: item[:options] || {}, user_defined: item[:user_defined])
        else
          raise H2gb::Vault::Memory::MemoryError("Unknown type: %s" % item[:type])
        end
      end
    end
  end
end
