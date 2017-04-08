##
# memory.rb
# Created April, 2017
# By Ron Bowes
#
# See: LICENSE.md
##

module H2gb
  module Vault
    class Memory
      def initialize()
        @memory = {}
      end

      def _delete_entry(entry:)
        entry[:address].upto(entry[:address] + entry[:length] - 1) do |i|
          # TODO: Version this instead
          @memory[i] = nil
        end
      end

      def _insert_entry(entry:)
        entry[:address].upto(entry[:address] + entry[:length] - 1) do |i|
          @memory[i] = entry
        end
      end

      def insert(address:, data:, length:)
        entry = {
          :address => address,
          :data => data,
          :length => length,
        }

        # Remove anything that's already there
        address.upto(address + length - 1) do |i|
          if not @memory[i].nil?
            _delete_entry(entry: @memory[i])
          end
        end

        _insert_entry(entry: entry)
      end

      def delete(address:)
        # TODO
      end

      def get(address:, length:)
        result = []
        i = address
        while(i < address + length)
          # If nothing is there, just go to the next memory
          if @memory[i].nil?
            i = i + 1
            next
          end

          # If something IS there, add it to the result...
          result << @memory[i]

          # ...and go to the address immediately following
          i = @memory[i][:address] + @memory[i][:length]
        end

        return result
      end
    end
  end
end
