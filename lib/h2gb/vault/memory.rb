##
# memory.rb
# Created April, 2017
# By Ron Bowes
#
# See: LICENSE.md
##

module H2gb
  module Vault
    # This is an entry for a single memory address, not a set of addresses.
    class MemoryEntry
      attr_reader :address, :entry

      def initialize(address:)
        @address = address
        @revision = 0
        @revisions = []
      end

      def _revision(revision)
        if revision == -1
          return @revision
        end
        return revision
      end

      def get(revision: -1)
        return @revisions[_revision(revision)]
      end

      def set(revision:, entry:)
        @revision = revision
        @revisions[@revision] = entry
      end

      def history()
        return @revisions
      end
    end

    class Memory
      def initialize()
        @memory = {}
        @revision = 0
        @in_transaction = false
        @mutex = Mutex.new()
      end

#      def transaction()
#        @mutex.synchronize() do
#          @in_transaction = true
#          @revision += 1
#          yield
#        end
#      end

      def insert(address:, length:, data:)
        @mutex.synchronize() do
          if not @in_transaction
            @revision += 1
          end

          # Remove anything that's already there
          address.upto(address + length - 1) do |i|
            if @memory[i] && @memory[i].get()
              current_entry = @memory[i].get()
              current_entry[:address].upto(current_entry[:address] + current_entry[:length] - 1) do |j|
                @memory[j].set(revision: @revision, entry: nil)
              end
            end
          end

          # Put the new entry into each address
          address.upto(address + length - 1) do |i|
            if @memory[i].nil?
              @memory[i] = MemoryEntry.new(address: i)
            end

            @memory[i].set(revision: @revision, entry: {
              :address => address,
              :length => length,
              :data => data,
            })
          end
        end
      end

      def get(address:, length:)
        result = []
        i = address
        while(i < address + length)
          if(@memory[i].nil?)
            i += 1
            next
          end

          entry = @memory[i].get()
          if not entry
            i += 1
            next
          end

          result << entry

          # Go to the address immediately following
          i = entry[:address] + entry[:length]
        end

        return result
      end
    end
  end
end
