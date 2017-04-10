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
      ##
      # Store an entry for a single memory address. That includes arbitrary data
      # as well as revision history.
      #
      # The purpose for this class is that each byte of memory needs to remember
      # its own revision. Rather than trying to maintain that information in a
      # series of hashes, it made sense to create an object that could track it
      # itself.
      ##
      class MemoryEntry
        attr_reader :address, :entry

        def initialize(address:)
          @address = address
          @revision = 0
          @history = {}
        end

        private
        def _revision(revision)
          if revision == -1
            return @revision
          end
          return revision
        end

        public
        def get(revision: -1)
          revision = _revision(revision)
          entry = @history[revision]
          if entry.nil?
            return {
              revision: revision,
              address: address,
              length: 1,
              data: nil,
              refs: [],
            }
          end

          return {
            revision: revision,
            address: entry[:address],
            length: entry[:length],
            data: entry[:data],
            refs: entry[:refs],
          }
        end

        public
        def set(revision:, address:, length:, data:, refs:)
          # TODO: Limit the number of revisions that we store
          @revision = revision
          @history[@revision] = {
            address: address,
            length: length,
            data: data,
            refs: refs,
          }
        end

        public
        def delete(revision:)
          @revision = revision
          @history[@revision] = nil
        end

        public
        def rollback(revision:)
          if @revision <= revision
            return
          end

          @revision = 0
          @history.keys.each() do |possible_rev|
            if possible_rev > revision
              return @revision
            end
            @revision = possible_rev
          end
        end
      end
      # Make the MemoryEntry class private so people can't accidentally use it.
      private_constant :MemoryEntry

      public
      def initialize()
        @memory = {}
        @revision = 0
        @in_transaction = false
        @mutex = Mutex.new()
      end

      public
      def transaction()
        @mutex.synchronize() do
          @in_transaction = true
          @revision += 1
          yield
        end
      end

      private
      def _insert_internal(address:, length:, data:, refs:)
        # Remove anything that's already there
        address.upto(address + length - 1) do |i|
          # If there's something there, and it isn't nil...
          if @memory[i]
            # Remove each address that that memory entry covers
            current_entry = @memory[i].get()
            # TODO: Maybe add current_entry.each_address()?
            current_entry[:address].upto(current_entry[:address] + current_entry[:length] - 1) do |j|
              @memory[j].delete(revision: @revision)
            end
          end
        end

        # Put the new entry into each address
        address.upto(address + length - 1) do |i|
          # Create the entry on-demand if it doesn't exist
          if @memory[i].nil?
            @memory[i] = MemoryEntry.new(address: i)
          end

          @memory[i].set(
            revision: @revision,
            address: address,
            length: length,
            data: data,
            refs: refs,
          )
        end
      end

      public
      def insert(address:, length:, data:, refs: nil) # TODO: refs
        if @in_transaction
          return _insert_internal(address: address, length: length, data: data, refs: refs)
        end

        # TODO: I don't think I'll allow changes outside transactions forever
        @mutex.synchronize() do
          @revision += 1
          return _insert_internal(address: address, length: length, data: data, refs: refs)
        end
      end

      public
      def get(address:, length:)
        result = []
        i = address
        while(i < address + length)
          if(@memory[i].nil?)
            i += 1
            next
          end

          entry = @memory[i].get()
          if entry[:data].nil?
            i += 1
            next
          end

          result << entry

          # Go to the address immediately following
          i = entry[:address] + entry[:length]
        end

        return result
      end

      public
      def rollback(revision:)
        if revision == 0
          return
        end

        # TODO: This is not going to scale well
        @memory.each_value() do |memory_entry|
          memory_entry.rollback(revision: revision)
        end
      end

      public
      def undo()
        rollback(revision: @revision - 1)
      end
    end
  end
end
