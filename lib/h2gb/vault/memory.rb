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
      class MemoryError < RuntimeError
      end

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
      # Make the MemoryEntry class private so people can't accidentally use it.
      private_constant :MemoryEntry

      class MemoryBlock
        def initialize()
          @memory = {}
        end

        def insert(entry:)
          entry.each_address() do |i|
            @memory[i] = entry
          end
        end

        def delete(entry:)
          entry.each_address() do |i|
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

      class MemoryTransaction
        attr_reader :revision

        ENTRY_INSERT = 0
        ENTRY_DELETE = 1

        OPPOSITES = {
          ENTRY_INSERT => ENTRY_DELETE,
          ENTRY_DELETE => ENTRY_INSERT,
        }

        def initialize()
          @revision = 0
          @undo_revision = 0
          @redo_buffer = []
          @revisions = []
        end

        def increment(undoable:, kill_redo_buffer:)
          @revision += 1
          @revisions[@revision] = {
            undoable: undoable,
            entries: [],
          }

          if kill_redo_buffer
            @undo_revision = @revision
            @redo_buffer = []
          end
        end

        def add_to_current_transaction(type:, entry:)
          @revisions[@revision][:entries] << {
            action: type,
            entry:  entry,
          }
        end

        def undo_transaction()
          # Go back until we find the first undoable revision
          @undo_revision.step(0, -1) do |revision|
            if revision == 0
              @undo_revision = 0
              return
            end

            if @revisions[revision][:undoable]
              @undo_revision = revision
              break
            end
          end

          # Create a new entry in the revisions list
          increment(undoable: false, kill_redo_buffer: false)

          # Mark the revision as no longer undoable (since we can't undo an undo)
          @revisions[@undo_revision][:undoable] = false

          # Go through the current @undo_revision backwards, and unapply each one
          @revisions[@undo_revision][:entries].reverse().each do |forward_entry|
            action = OPPOSITES[forward_entry[:action]]
            if action.nil?
              raise(MemoryError, "Unknown revision action: %d" % forward_entry[:action])
            end

            yield(action, forward_entry[:entry])
          end

          # Add the entry to the redo buffer
          @redo_buffer << @revisions[@undo_revision]
        end

        def redo_transaction()
          # If there's nothing in our redo buffer, just return
          if @redo_buffer.length == 0
            return
          end

          # Create a new undoable entry in the revisions list
          increment(undoable: true, kill_redo_buffer: false)

          # Go through the current @undo_revision backwards, and unapply each one
          redo_revision = @redo_buffer.pop()
          redo_revision[:entries].each do |redo_entry|
            yield(redo_entry[:action], redo_entry[:entry])
          end

          return true
        end
      end

      public
      def initialize()
        @memory_block = MemoryBlock.new()
        @transactions = MemoryTransaction.new()
        @in_transaction = false
        @mutex = Mutex.new()
      end

      public
      def transaction()
        @mutex.synchronize() do
          @in_transaction = true

          @transactions.increment(
            undoable: true,
            kill_redo_buffer: true,
          )
          yield
        end
      end

      private
      def _delete_internal(entry:)
        @transactions.add_to_current_transaction(type: MemoryTransaction::ENTRY_DELETE, entry: entry)
        @memory_block.delete(entry: entry)
      end

      private
      def _insert_internal(entry:)
        @memory_block.each_entry_in_range(address: entry.address, length: entry.length) do |e|
          _delete_internal(entry: e)
        end
        @memory_block.insert(entry: entry)

        @transactions.add_to_current_transaction(type: MemoryTransaction::ENTRY_INSERT, entry: entry)
      end

      public
      def insert(address:, length:, data:, refs: nil) # TODO: refs
        if not @in_transaction
          raise(MemoryError, "Calls to insert() must be wrapped in a transaction!")
        end

        entry = MemoryEntry.new(address: address, length: length, data: data, refs: refs)
        _insert_internal(entry: entry)
      end

      public
      def delete(address:, length:)
        if not @in_transaction
          raise(MemoryError, "Calls to insert() must be wrapped in a transaction!")
        end

        @memory_block.each_entry_in_range(address: address, length: length) do |entry|
          _delete_internal(entry: entry)
        end
      end

      public
      def get(address:, length:)
        result = {
          revision: @transactions.revision,
          entries: [],
        }

        @memory_block.each_entry_in_range(address: address, length: length) do |entry|
          result[:entries] << {
            address: entry.address,
            data:    entry.data,
            length:  entry.length,
            refs:    entry.refs,
          }
        end

        return result
      end

      public
      def undo()
        @transactions.undo_transaction() do |action, entry|
          if action == MemoryTransaction::ENTRY_INSERT
            _insert_internal(entry: entry)
          elsif action == MemoryTransaction::ENTRY_DELETE
            _delete_internal(entry: entry)
          else
            raise(MemoryError, "Unknown revision action: %d" % action)
          end
        end
      end

      public
      def redo()
        @transactions.redo_transaction() do |action, entry|
          if action == MemoryTransaction::ENTRY_INSERT
            _insert_internal(entry: entry)
          elsif action == MemoryTransaction::ENTRY_DELETE
            _delete_internal(entry: entry)
          else
            raise(MemoryError, "Unknown revision action: %d" % redo_entry[:action])
          end
        end

        return true
      end

      public
      def to_s()
        return "Revision: %d => %s" % [@transactions.revision, @memory_block]
      end
    end
  end
end
