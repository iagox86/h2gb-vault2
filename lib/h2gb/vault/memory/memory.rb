##
# memory.rb
# Created April, 2017
# By Ron Bowes
#
# See: LICENSE.md
#
# Represents an abstraction of a process's memory, including addresses,
# references, cross-references, undo/redo, save/load, and more!
##

require 'h2gb/vault/memory/memory_block'
require 'h2gb/vault/memory/memory_entry'
require 'h2gb/vault/memory/memory_error'
require 'h2gb/vault/memory/memory_transaction'

module H2gb
  module Vault
    class Memory
      ENTRY_INSERT = :insert
      ENTRY_DELETE = :delete

      public
      def initialize(raw:)
        @memory_block = MemoryBlock.new(raw: raw)
        @transactions = MemoryTransaction.new(opposites: {
          ENTRY_INSERT => ENTRY_DELETE,
          ENTRY_DELETE => ENTRY_INSERT,
        })
        @in_transaction = false
        @mutex = Mutex.new()
      end

      public
      def transaction()
        @mutex.synchronize() do
          @in_transaction = true

          @transactions.increment()
          yield
        end
      end

      private
      def _delete_internal(entry:)
        @transactions.add_to_current_transaction(type: ENTRY_DELETE, entry: entry)
        @memory_block.delete(entry: entry)
      end

      private
      def _insert_internal(entry:)
        @memory_block.each_entry_in_range(address: entry.address, length: entry.length) do |address, type, this_entry, raw|
          if type == :entry
            _delete_internal(entry: this_entry)
          end
        end
        @memory_block.insert(entry: entry)

        @transactions.add_to_current_transaction(type: ENTRY_INSERT, entry: entry)
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

        @memory_block.each_entry_in_range(address: address, length: length) do |this_address, type, entry, raw|
          if type == :entry
            _delete_internal(entry: entry)
          end
        end
      end

      public
      def get(address:, length:)
        result = {
          revision: @transactions.revision,
          entries: [],
        }

        @memory_block.each_entry_in_range(address: address, length: length) do |this_address, type, entry, raw|
          if type == :entry
            result[:entries] << {
              address: entry.address,
              data:    entry.data,
              length:  entry.length,
              refs:    entry.refs,
            }
          end
        end

        return result
      end

      private
      def _apply(action:, entry:)
        if action == ENTRY_INSERT
          _insert_internal(entry: entry)
        elsif action == ENTRY_DELETE
          _delete_internal(entry: entry)
        else
          raise(MemoryError, "Unknown revision action: %d" % action)
        end
      end

      public
      def undo()
        @transactions.undo_transaction() do |action, entry|
          _apply(action: action, entry: entry)
        end
      end

      public
      def redo()
        @transactions.redo_transaction() do |action, entry|
          _apply(action: action, entry: entry)
        end
      end

      public
      def to_s()
        return "Revision: %d => %s" % [@transactions.revision, @memory_block]
      end
    end
  end
end
