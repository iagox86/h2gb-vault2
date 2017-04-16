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
        attr_reader :address, :length, :data, :refs, :revision

        def initialize(address:, length:, data:, refs:, revision:)
          if length < 0
            raise(H2gb::Vault::Memory::MemoryError, "Memory length can't be negative")
          end

          if address < 0
            raise(H2gb::Vault::Memory::MemoryError, "Memory address can't be negative")
          end

          if revision < 0
            raise(H2gb::Vault::Memory::MemoryError, "Revision can't be negative")
          end

          @address = address
          @length = length
          @data = data
          @refs = refs
          @revision = revision
        end

        def each_address()
          @address.upto(@address + @length - 1) do |i|
            yield(i)
          end
        end

        def to_s()
          return "%p :: 0x%x bytes => %s" % [@address, @length, @data]
        end
      end
    end
  end
end
