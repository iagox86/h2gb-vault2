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
require 'h2gb/vault/memory/memory_refs'
require 'h2gb/vault/memory/memory_transaction'

module H2gb
  module Vault
    class Memory
      attr_reader :transactions, :memory_block

      ENTRY_DEFINE = :define
      ENTRY_UNDEFINE = :undefine

      UPDATE_USER_DEFINED_FORWARD = :update_user_defined_forward
      UPDATE_USER_DEFINED_BACKWARD = :update_user_defined_backward

      public
      def initialize(raw:)
        @memory_block = MemoryBlock.new(raw: raw)
        @transactions = MemoryTransaction.new(opposites: {
          ENTRY_DEFINE => ENTRY_UNDEFINE,
          ENTRY_UNDEFINE => ENTRY_DEFINE,

          UPDATE_USER_DEFINED_FORWARD => UPDATE_USER_DEFINED_BACKWARD,
          UPDATE_USER_DEFINED_BACKWARD => UPDATE_USER_DEFINED_FORWARD,
        })
        @in_transaction = false

        @refs = {
          code: MemoryRefs.new(),
          data: MemoryRefs.new(),
        }

        @mutex = Mutex.new()
      end

      public
      def raw()
        return @memory_block.raw
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
      def _define_internal(entry:)
        @memory_block.each_entry_in_range(address: entry.address, length: entry.length, include_undefined: false) do |this_address, this_entry, raw|
          _undefine_internal(entry: this_entry)
        end

        @memory_block.insert(entry: entry, revision: @transactions.revision)

        @transactions.add_to_current_transaction(type: ENTRY_DEFINE, entry: entry)
      end

      private
      def _undefine_internal(entry:)
        @transactions.add_to_current_transaction(type: ENTRY_UNDEFINE, entry: entry)
        @memory_block.delete(entry: entry, revision: @transactions.revision)
      end

      private
      def _update_user_defined_internal(entry:, new_user_defined:)
        @transactions.add_to_current_transaction(type: UPDATE_USER_DEFINED_FORWARD, entry: {
          entry: entry,
          old_user_defined: entry.user_defined.clone(),
          new_user_defined: new_user_defined.clone(),
        })
        @memory_block.update_user_defined(entry: entry, user_defined: new_user_defined, revision: @transactions.revision)
      end

      private
      def _apply(action:, entry:)
        if action == ENTRY_DEFINE
          _define_internal(entry: entry)
        elsif action == ENTRY_UNDEFINE
          _undefine_internal(entry: entry)
        elsif action == UPDATE_USER_DEFINED_BACKWARD
          _update_user_defined_internal(entry: entry[:entry], new_user_defined: entry[:old_user_defined])
        elsif action == UPDATE_USER_DEFINED_FORWARD
          _update_user_defined_internal(entry: entry[:entry], new_user_defined: entry[:new_user_defined])
        else
          raise(MemoryError, "Unknown revision action: %s" % action)
        end
      end

      public
      def define(address:, type:, value:, length:, refs:{}, user_defined:{}, comment:nil)
        if not @in_transaction
          raise(MemoryError, "Calls to define() must be wrapped in a transaction!")
        end

        entry = MemoryEntry.new(address: address, type: type, value: value, length: length, refs: refs, user_defined: user_defined, comment: comment)
        _define_internal(entry: entry)
      end

      public
      def undefine(address:, length:1)
        if not @in_transaction
          raise(MemoryError, "Calls to undefine() must be wrapped in a transaction!")
        end

        @memory_block.each_entry_in_range(address: address, length: length) do |this_address, entry, raw|
          _undefine_internal(entry: entry)
        end
      end

      public
      def get_user_defined(address:)
        entry = @memory_block.get(address: address)
        if entry.nil?
          return {}
        end

        return entry.user_defined
      end

      public
      def replace_user_defined(address:, user_defined:)
        if not @in_transaction
          raise(MemoryError, "Calls to replace_user_defined() must be wrapped in a transaction!")
        end

        entry, _ = @memory_block.get(address: address, define_by_default: false)

        # Automatically define the entry if it doesn't exist
        if entry.nil?
          entry = MemoryEntry.default(address: address, raw: @memory_block.raw[address].ord())
          _define_internal(entry: entry)
        end

        _update_user_defined_internal(entry: entry, new_user_defined: user_defined)
      end

      public
      def update_user_defined(address:, user_defined:)
        if not @in_transaction
          raise(MemoryError, "Calls to update_user_defined() must be wrapped in a transaction!")
        end
        if !user_defined.is_a?(Hash)
          raise(MemoryError, "user_defined must be a hash")
        end

        entry, _ = @memory_block.get(address: address, define_by_default: false)

        # Automatically define the entry if it doesn't exist
        if entry.nil?
          entry = MemoryEntry.default(address: address, raw: @memory_block.raw[address].ord())
          _define_internal(entry: entry)
        end

        _update_user_defined_internal(entry: entry, new_user_defined: entry.user_defined.merge(user_defined))
      end

      public
      def get(address:, length: 1, since: -1)
        @mutex.synchronize() do
          result = {
            revision: @transactions.revision,
            entries: [],
          }

          @memory_block.each_entry_in_range(address: address, length: length, since: since) do |this_address, entry, raw, xrefs|

            result[:entries] << {
              address:      this_address,
              type:         entry.type,
              value:        entry.value,
              length:       entry.length,
              refs:         entry.refs,
              user_defined: entry.user_defined,
              comment:      entry.comment,
              raw:          raw,
              xrefs:        xrefs,
            }
          end

          return result
        end
      end

      public
      def get_single(address:)
        return get(address: address, length: 1, since: -1)[:entries].pop()
      end

      public
      def get_all()
        return get(address: 0, length: @memory_block.raw.length, since: -1)
      end

      public
      def raw()
        return @memory_block.raw
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
        return [
          "Revision: %d" % @transactions.revision,
          "--",
          "%s" % [@memory_block.to_s()],
        ].join("\n")
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

        if memory.class != Memory
          raise(MemoryError, "Couldn't load the file")
        end

        return memory
      end
    end
  end
end
