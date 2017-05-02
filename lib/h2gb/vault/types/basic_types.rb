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
    class BasicTypes
      BIG_ENDIAN = :big_endian
      LITTLE_ENDIAN = :little_endian

      def initialize(memory:)
        @memory = memory
      end

      def _sanity_check(offset:, length:)
        if offset < 0
          raise(H2gb::Vault::Memory::MemoryError, "Offset must be positive")
        end
        if offset + length > @memory.memory_block.raw.length
          raise(H2gb::Vault::Memory::MemoryError, "Variable would go off the end of memory")
        end
      end

      def uint8_t(offset:)
        _sanity_check(offset: offset, length: 1)

        value = @memory.memory_block.raw[offset].ord()
        @memory.transaction() do
          @memory.insert(address: offset, length: 1, data: {
            type: :uint8_t,
            value: value,
          })
        end
      end

      def uint16_t(offset:, endian:)
        _sanity_check(offset: offset, length: 2)

        if endian == BIG_ENDIAN
          value = @memory.memory_block.raw[offset,2].unpack("n").pop()
        elsif
          value = @memory.memory_block.raw[offset,2].unpack("v").pop()
        else
          raise(H2gb::Vault::Memory::MemoryError, "Unknown endian type: %s" % endian.to_s())
        end

        @memory.transaction() do
          @memory.insert(address: offset, length: 2, data: {
            type: :uint16_t,
            value: value,
            endian: endian,
          })
        end
      end
    end
  end
end
