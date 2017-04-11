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
module H2gb
  module Vault
    class Memory
      class MemoryEntry
        attr_reader :address, :length, :data, :refs
        def initialize(address:, length:, data:, refs:)
          @address = address
          @length = length
          @data = data
          @refs = refs
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
