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
        @revision = 0
      end

      def _set_single(address:, entry:)
        if @memory[address].nil?
          @memory[address] = []
        end

        # Don't add a new entry if it isn't changing
        if @memory[address][-1] == entry
          return
        end

        @memory[address] << entry
      end

      def _delete_entry(entry:)
        entry[:address].upto(entry[:address] + entry[:length] - 1) do |i|
          _set_single(address:i, entry:nil)
        end
      end

      def _insert_entry(entry:)
        entry[:address].upto(entry[:address] + entry[:length] - 1) do |i|
          _set_single(address:i, entry:entry)
        end
      end

      def insert(address:, data:, length:)
        @revision += 1

        entry = {
          :address => address,
          :data => data,
          :length => length,
        }

        # Remove anything that's already there
        address.upto(address + length - 1) do |i|
          if not @memory[i].nil? and not @memory[i][-1].nil?
            _delete_entry(entry: @memory[i][-1])
          end
        end

        _insert_entry(entry: entry)
      end

      def delete(address:)
        @revision += 1
        # TODO
      end

      def get(address:, length:)
        result = []
        i = address
        while(i < address + length)
          # If nothing is there, just go to the next memory
          if @memory[i].nil? or @memory[i][-1].nil?
            i = i + 1
            next
          end

          # If something IS there, add it to the result...
          entry = @memory[i][-1]

          result << entry

          # ...and go to the address immediately following
          i = entry[:address] + entry[:length]
        end

        return result
      end
    end
  end
end
