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

require 'yaml'

require 'h2gb/vault/memory/memory_block'
require 'h2gb/vault/memory/memory_entry'
require 'h2gb/vault/memory/memory_error'
require 'h2gb/vault/memory/memory_transaction'

module H2gb
  module Vault
    class Memory
      attr_reader :transactions

      ENTRY_INSERT = :insert
      ENTRY_DELETE = :delete

      ENTRY_EDIT_FORWARD = :edit_forward
      ENTRY_EDIT_BACKWARD = :edit_backward

      public
      def initialize(raw:)
        @memory_block = MemoryBlock.new(raw: raw)
        @transactions = MemoryTransaction.new(opposites: {
          ENTRY_INSERT => ENTRY_DELETE,
          ENTRY_DELETE => ENTRY_INSERT,

          ENTRY_EDIT_FORWARD => ENTRY_EDIT_BACKWARD,
          ENTRY_EDIT_BACKWARD => ENTRY_EDIT_FORWARD,
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

          @in_transaction = false
        end
      end

      private
      def _insert_internal(entry:)
        @memory_block.each_entry_in_range(address: entry.address, length: entry.length) do |this_address, this_entry, raw, xrefs|
          if this_entry
            _delete_internal(entry: this_entry)
          end
        end

        @memory_block.insert(entry: entry, revision: @transactions.revision)

        @transactions.add_to_current_transaction(type: ENTRY_INSERT, entry: entry)
      end

      public
      def insert(address:, length:, data:, refs: nil)
        if not @in_transaction
          raise(MemoryError, "Calls to insert() must be wrapped in a transaction!")
        end

        entry = MemoryEntry.new(address: address, length: length, data: data, refs: refs)
        _insert_internal(entry: entry)
      end

      private
      def _delete_internal(entry:)
        @transactions.add_to_current_transaction(type: ENTRY_DELETE, entry: entry)
        @memory_block.delete(entry: entry, revision: @transactions.revision)
      end

      public
      def delete(address:, length:)
        if not @in_transaction
          raise(MemoryError, "Calls to insert() must be wrapped in a transaction!")
        end

        @memory_block.each_entry_in_range(address: address, length: length) do |this_address, this_entry, raw, xrefs|
          if this_entry
            _delete_internal(entry: this_entry)
          end
        end
      end

      private
      def _edit_internal(entry:, old_data:, new_data:)
        @transactions.add_to_current_transaction(type: ENTRY_EDIT_FORWARD, entry: {
          entry: entry,
          old_data: entry.data,
          new_data: new_data,
        })
        @memory_block.edit(entry: entry, data: new_data, revision: @transactions.revision)
      end

      public
      def edit(address:, new_data:)
        if not @in_transaction
          raise(MemoryError, "Calls to edit() must be wrapped in a transaction!")
        end

        entry = @memory_block.get(address: address)
        if entry.nil? || entry.data.nil?
          raise(MemoryError, "Tried to edit undefined data")
        end

        _edit_internal(entry: entry, old_data: entry.data, new_data: new_data)
      end

      public
      def get(address:, length: 1, since: -1)
        @mutex.synchronize() do
          result = {
            revision: @transactions.revision,
            entries: [],
          }

          @memory_block.each_entry_in_range(address: address, length: length, since: since) do |this_address, entry, raw, xrefs|

            if entry
              result[:entries] << {
                address: entry.address,
                data:    entry.data,
                length:  entry.length,
                refs:    entry.refs,
                raw:     raw,
                xrefs:   xrefs,
              }
            else
              result[:entries] << {
                address: this_address,
                data:    nil,
                length:  1,
                refs:    [],
                raw:     raw,
                xrefs:   xrefs,
              }
            end
          end

          return result
        end
      end

      public
      def get_raw()
        return @memory_block.raw
      end

      private
      def _apply(action:, entry:)
        if action == ENTRY_INSERT
          _insert_internal(entry: entry)
        elsif action == ENTRY_DELETE
          _delete_internal(entry: entry)
        elsif action == ENTRY_EDIT_BACKWARD
          _edit_internal(entry: entry[:entry], new_data: entry[:old_data], old_data: entry[:new_data])
        elsif action == ENTRY_EDIT_FORWARD
          _edit_internal(entry: entry[:entry], new_data: entry[:new_data], old_data: entry[:old_data])
        else
          raise(MemoryError, "Unknown revision action: %s" % action)
        end
      end

      public
      def undo()
        @mutex.synchronize() do
          @transactions.undo_transaction() do |action, entry|
            _apply(action: action, entry: entry)
          end
        end
      end

      public
      def redo()
        @mutex.synchronize() do
          @transactions.redo_transaction() do |action, entry|
            _apply(action: action, entry: entry)
          end
        end
      end

      public
      def to_s()
        @mutex.synchronize() do
          return "Revision: %d => %s" % [@transactions.revision, @memory_block]
        end
      end

      public
      def dump()
        @mutex.synchronize() do
          return YAML::dump(self)
        end
      end

      public
      def self.load(str)
        memory = YAML::load(str)

        if memory.class != H2gb::Vault::Memory
          raise(MemoryError, "Couldn't load the file")
        end

        return memory
      end
    end
  end
end
