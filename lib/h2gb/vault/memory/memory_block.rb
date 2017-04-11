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
        def initialize()
          @memory = {}
        end

        def insert(entry:)
          entry.each_address() do |i|
            if @memory[i]
              raise(H2gb::Vault::Memory::MemoryError, "Tried to write to memory that's already in use")
            end
            @memory[i] = entry
          end
        end

        def delete(entry:)
          entry.each_address() do |i|
            if @memory[i].nil?
              raise(H2gb::Vault::Memory::MemoryError, "Tried to clear memory that's not in use")
            end
            @memory[i] = nil
          end
        end

        def each_entry_in_range(address:, length:)
          i = address

          while i < address + length
            if @memory[i]
              # Pre-compute the next value of i, in case we're deleting the memory
              next_i = @memory[i].address + @memory[i].length
              yield(@memory[i])
              i = next_i
            else
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
