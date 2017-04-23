##
# memory_entry.rb
# Created April, 2017
# By Ron Bowes
#
# See: LICENSE.md
#
# A single entry, used in the memory class. A simple class, but abstracting it
# out cleaned it up.
##

require 'h2gb/vault/memory/memory_error'

module H2gb
  module Vault
    class Memory
      class MemoryEntry
        attr_reader :address, :length, :refs
        attr_accessor :data

        def initialize(address:, length:, data:, refs:)
          if length < 0
            raise(H2gb::Vault::Memory::MemoryError, "Memory length can't be negative")
          end

          if address < 0
            raise(H2gb::Vault::Memory::MemoryError, "Memory address can't be negative")
          end

          @address = address
          @length = length
          @data = data
          @refs = refs || [] # Don't let refs be nil
        end

        def each_address()
          @address.upto(@address + @length - 1) do |i|
            yield(i)
          end
        end

        def value_to_s(value:, type:, subtype:)
          if type == :uint8_t
            return "0x%02x" % value
          elsif type == :uint16_t
            return "0x%04x" % value
          elsif type == :uint32_t
            return "0x%08x" % value
          elsif type == :offset
            return "0x%08x" % value
          elsif type == :rgb
            return "#" + value.bytes.map() { |b| '%02x' % b }.join()
          elsif type == :array
            return value.map() { value_to_s(value: value, type: subtype, subtype: nil) }
          else
            return "Unknown type: %s" % type
          end
        end

        def to_s()
          if @data
            return value_to_s(value: @data[:value], type: @data[:type], subtype: @data[:subtype])
          else
            return "n/a"
          end
        end
      end
    end
  end
end
