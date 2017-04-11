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

      ENTRY_INSERT = 0
      ENTRY_DELETE = 1

      public
      def initialize()
        @memory = {}
        @revision = 0
        @undo_revision = 0
        @redo_buffer = []
        @revisions = []
        @in_transaction = false
        @mutex = Mutex.new()
        @redoable_steps = 0
      end

      public
      def transaction()
        @mutex.synchronize() do
          @in_transaction = true
          @revision += 1
          @undo_revision = @revision
          @redo_buffer = []
          @revisions[@revision] = {
            undoable: true,
            entries:  [],
          }
          yield
        end
      end

      private
      def _each_entry_in_range(address:, length:)
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

      private
      def _delete_internal(entry:)
        @revisions[@revision][:entries] << {
          action: ENTRY_DELETE,
          entry:  entry,
        }

        entry.each_address() do |i|
          @memory[i] = nil
        end
      end

      private
      def _insert_internal(entry:)
        _each_entry_in_range(address: entry.address, length: entry.length) do |e|
          _delete_internal(entry: e)
        end
        entry.each_address() do |i|
          @memory[i] = entry
        end

        @revisions[@revision][:entries] << {
          action: ENTRY_INSERT,
          entry:  entry,
        }
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

        _each_entry_in_range(address: address, length: length) do |entry|
          _delete_internal(entry: entry)
        end
      end

      public
      def get(address:, length:)
        result = {
          revision: @revision,
          entries: [],
        }

        _each_entry_in_range(address: address, length: length) do |entry|
          result[:entries] << {
            address: entry.address,
            data:    entry.data,
            length:  entry.length,
            refs:    entry.refs,
          }
        end

        return result
      end

      # TODO: I can probably extract all the revision stuff into its own class
      public
      def undo()
        # Go back until we find the first undoable revision
        @undo_revision.step(0, -1) do |revision|
          if revision == 0
            @undo_revision = 0
            return false
          end

          if @revisions[revision][:undoable]
            @undo_revision = revision
            break
          end
        end

        # Create a new entry in the revisions list
        @revision += 1
        @revisions[@revision] = {
          undoable: false,
          entries: [],
        }

        # Mark the revision as no longer undoable (since we can't undo an undo)
        @revisions[@undo_revision][:undoable] = false

        # Go through the current @undo_revision backwards, and unapply each one
        @revisions[@undo_revision][:entries].reverse().each do |forward_entry|
          if forward_entry[:action] == ENTRY_INSERT
            _delete_internal(entry: forward_entry[:entry])
          elsif forward_entry[:action] == ENTRY_DELETE
            _insert_internal(entry: forward_entry[:entry])
          else
            raise(MemoryError, "Unknown revision action: %d" % forward_entry[:action])
          end
        end

        # Add the entry to the redo buffer
        @redo_buffer << @revisions[@undo_revision]

        return true
      end

      public
      def redo()
        # If there's nothing in our redo buffer, just return
        if @redo_buffer.length == 0
          return false
        end

        # Create a new undoable entry in the revisions list
        @revision += 1
        @revisions[@revision] = {
          undoable: true,
          entries: [],
        }

        # Go through the current @undo_revision backwards, and unapply each one
        redo_revision = @redo_buffer.pop()
        redo_revision[:entries].each do |redo_entry|
          if redo_entry[:action] == ENTRY_INSERT
            _insert_internal(entry: redo_entry[:entry])
          elsif redo_entry[:action] == ENTRY_DELETE
            _delete_internal(entry: redo_entry[:entry])
          else
            raise(MemoryError, "Unknown revision action: %d" % redo_entry[:action])
          end
        end

        return true
      end

      public
      def to_s()
        return "Revision: %d => %s" % [@revision, (@memory.map() { |m, e| e.to_s() }).join("\n")]
      end
    end
  end
end
