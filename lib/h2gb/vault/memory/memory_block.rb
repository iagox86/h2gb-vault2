##
# memory_block.rb
# Created April, 2017
# By Ron Bowes
#
# See: LICENSE.md
#
# Represents a memory layout as a series of multi-byte entries with associated
# data.
##
module H2gb
  module Vault
    class Memory
      class MemoryBlock
        def initialize(raw:, revision:0)
          @raw = raw
          @memory = {}

          @raw.bytes().each_with_index() do |_, index|
            @memory[index] = {
              revision: revision,
              entry: nil,
            }
          end
        end

        def insert(entry:, revision:)
          entry.each_address() do |i|
            if @memory[i][:entry]
              raise(H2gb::Vault::Memory::MemoryError, "Tried to write to memory that's already in use")
            end
            if @raw[i].nil?
              raise(H2gb::Vault::Memory::MemoryError, "Tried to create an entry outside of the memory range")
            end

            @memory[i] = {
              revision: revision,
              entry: entry,
            }
          end
        end

        def delete(entry:, revision:)
          entry.each_address() do |i|
            if @memory[i][:entry].nil?
              raise(H2gb::Vault::Memory::MemoryError, "Tried to clear memory that's not in use")
            end
            @memory[i] = {
              revision: revision,
              entry: nil,
            }
          end
        end

        def _get_raw(entry:)
          return @raw[entry.address, entry.length].bytes()
        end

        def each_entry_in_range(address:, length:, since: 0)
          i = address

          while i < address + length
            if @memory[i].nil?
              raise(H2gb::Vault::Memory::MemoryError, "Tried to retrieve an entry outside of the range")
            end

            entry = @memory[i][:entry]
            revision = @memory[i][:revision]

            if entry
              # Pre-compute the next value of i, in case we're deleting the memory
              next_i = entry.address + entry.length

              if revision > since
                yield(entry.address, entry, _get_raw(entry: entry))
              end

              i = next_i
            else
              if revision > since
                yield(i, nil, [@raw[i].ord])
              end

              i += 1
            end
          end
        end

        def to_s()
          return (@memory.map() { |m, e| e.to_s() }).join("\n")
        end
      end
    end
  end
end
