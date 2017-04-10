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
          @revisions = {}
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
          return @revisions[_revision(revision)]
        end

        public
        def set(revision:, entry:)
          @revision = revision
          @revisions[@revision] = entry
        end

        public
        def rollback(revision:)
          if @revision <= revision
            return
          end

          @revision = 0
          @revisions.keys.each() do |possible_rev|
            if possible_rev > revision
              return @revision
            end
            @revision = possible_rev
          end
        end

        public
        def history()
          return @revisions
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
      def _insert_internal(address:, length:, data:)
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

      public
      def insert(address:, length:, data:)
        if @in_transaction
          return _insert_internal(address: address, length: length, data: data)
        end

        @mutex.synchronize() do
          @revision += 1
          return _insert_internal(address: address, length: length, data: data)
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
